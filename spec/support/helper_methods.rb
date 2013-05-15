module RSpecHelpers
  def relative_path(path)
    RSpec::Core::Metadata.relative_path(path)
  end

  def safely
    Thread.new do
      $-w = false
      $SAFE = 3
      $-w = true
      yield
    end.join

    # $SAFE is not supported on Rubinius
    unless defined?(Rubinius)
      expect($SAFE).to eql 0 # $SAFE should not have changed in this thread.
    end
  end

end
