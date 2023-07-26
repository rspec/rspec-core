require 'socket'

module RSpec::Core
  RSpec.describe OutputWrapper do
    let(:socket_pair) { UNIXSocket.pair }
    let(:output) { socket_pair.first }
    let(:destination) {socket_pair.last}
    let(:wrapper) { OutputWrapper.new(output) }

    it 'redirects IO method calls to the wrapped object' do
      wrapper.puts('message')
      wrapper.print('another message')
      expect(destination.recv(32)).to eq("message\nanother message")
    end

    it 'redirects unknown method calls to the wrapped object' do
      expect(output).to receive(:addr).with(no_args)
      wrapper.addr
    end

    describe '#output=' do
      let(:another_output) { StringIO.new }

      it 'changes the output stream' do
        wrapper.output = another_output
        wrapper.puts('message')
        expect(another_output.string).to eq("message\n")
      end
    end
  end
end
