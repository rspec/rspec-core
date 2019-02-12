require 'tmpdir'
require 'rspec/support/spec/in_sub_process'

module RSpec
  module Core
    module DidYouMean
      RSpec.describe Proximity do
        # port of https://github.com/yuki24/did_you_mean/blob/master/test/edit_distance/jaro_winkler_test.rb
        describe 'should have correct jaro_winkler distance' do
          it { check_distance 0.9667, 'henka',      'henkan' }
          it { check_distance 1.0, 'henka',      'henka' }
          it { check_distance 1.0,    'al',         'al' }
          it { check_distance 0.9611, 'martha',     'marhta' }
          it { check_distance 0.8324, 'jones',      'johnson' }
          it { check_distance 0.9167, 'abcvwxyz',   'zabcvwxy' }
          it { check_distance 0.9583, 'abcvwxyz',   'cabvwxyz' }
          it { check_distance 0.84,   'dwayne',     'duane' }
          it { check_distance 0.8133, 'dixon',      'dicksonx' }
          it { check_distance 0.0,    'fvie',       'ten' }
          it { check_distance 0.9067, 'does_exist', 'doesnt_exist' }
          it { check_distance 1.0, 'x', 'x' }
        end

        describe 'should have correct jarowinkler distance with utf8 strings' do
          # This test commented out because failed with 1.9.2 and 1.9.3
          # works in 2.0.0 so probably a bug in 1.9.1, 1.9.2 and 1.9.3
          # it { check_distance 0.9818, '變形金剛4:絕跡重生', '變形金剛4: 絕跡重生' }
          it { check_distance 0.8222, '連勝文',             '連勝丼' }
          it { check_distance 0.8222, '馬英九',             '馬英丸' }
          it { check_distance 0.6667, '良い',               'いい' }
        end

        describe 'codepoints' do
          let(:dym_p) { DidYouMean::Proximity.new('', '') }
          it 'should work in english' do
            expect(dym_p.send(:codepoints, 'hello world')).to eq [104, 101, 108, 108, 111, 32, 119, 111, 114, 108, 100]
          end
          it 'should work with utf8 strings if ruby_version_high_enough' do
            if ruby_version_high_enough?
              expect(dym_p.send(:codepoints, "你好世界")).to eq [20320, 22909, 19990, 30028]
            end
          end
        end

        private

        def check_distance(score, str1, str2)
          expect(DidYouMean::Proximity.new(str1, str2).call.round(4)).to eq score
        end

        # checks ruby version high enough to support string.codepoints
        def ruby_version_high_enough?
          Gem::Version.new(RUBY_VERSION) >= Gem::Version.new('1.9.1') if defined? RUBY_VERSION
          return false unless defined? JRUBY_VERSION
          Gem::Version.new(JRUBY_VERSION) >= Gem::Version.new('1.9.1')
        end
      end
    end
  end
end
