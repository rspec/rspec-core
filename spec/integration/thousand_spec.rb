require 'rspec/support/spec/in_sub_process'

module RSpec::Core
  include RSpec::Support::InSubProcess

  if RUBY_VERSION.to_f >= 2.2
    RSpec.describe "RSpec", :slow do
      def measure(cmd, *args)
        Dir.mktmpdir do |dir|
          yield dir
          start = Time.now
          path = File.absolute_path(Bundler.which(cmd))
          Open3.popen3(path + ' ' + args.join(" "), chdir: dir) do |_, stdout, stderr|
            stdout.read
            stderr.read
          end
          return Time.now - start
        end
      end

      # Calculates how many tests / second given tool can run
      def benchmark(files, tests, delay)
        ruby_timing = measure 'ruby', 'test.rb' do |dir|
          File.write File.join(dir, 'test.rb'), """
            $:<<'spec'  # add to load path
            files = Dir.glob('spec/**/*.rb')
            files.each{|file| require file.gsub(/^spec\\/|\\.rb$/,'')}
          """

          Dir.mkdir File.join(dir, 'spec')
          files.times do |i|
            File.write File.join(dir, 'spec', "test#{i}_spec.rb"), """
              require 'test/unit'

              class TestMeme#{i} < Test::Unit::TestCase
                def setup
                  sleep(#{delay/2})
                  @answer = 42
                end
            """ + (1..tests).map { |j| """
                def test_simple_#{j}
                  sleep(#{delay/2})
                  assert_equal(#{42 + j}, @answer + #{j})
                end
            """ }.join("\n") + """
              end
            """
          end
        end

        rspec_timing = measure('exe/rspec') do |dir|
          Dir.mkdir File.join(dir, 'spec')
          files.times do |i|
            File.write File.join(dir, 'spec', "test#{i}_spec.rb"), """
              RSpec.describe 'test#{i}' do
                before(:each) do
                  sleep(#{delay/2})
                  @answer = 42
                end
            """ + (1..tests).map { |j| """
                it 'works' do
                  sleep(#{delay/2})
                  expect(@answer + #{j}).to be(#{42 + j})
                end
            """ }.join("\n") + """
              end
            """
          end
        end

        [
          rspec_timing,
          ruby_timing
        ]
      end

      it 'executes 1000 tiny specs in 100 files as fast as minitest' do
        in_sub_process do
          require 'bundler'
          require 'open3'

          rspec_timing, ruby_timing = benchmark(100, 10, 0.0001)
          expect(rspec_timing / ruby_timing).to be < 1.2 # can we do better?
        end
      end

      it 'executes 1000 small specs in 100 files as fast as minitest' do
        in_sub_process do
          require 'bundler'
          require 'open3'

          rspec_timing, ruby_timing = benchmark(100, 10, 0.001)
          expect(rspec_timing / ruby_timing).to be < 1.1 # can we do better?
        end
      end

      it 'executes 100 specs in 50 files as fast as minitest' do
        in_sub_process do
          require 'bundler'
          require 'open3'

          rspec_timing, ruby_timing = benchmark(50, 2, 0.01)
          expect(rspec_timing / ruby_timing).to be < 1.05 # can we do better?
        end
      end
    end
  end

end
