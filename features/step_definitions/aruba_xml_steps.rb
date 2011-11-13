require 'nokogiri'

module ArubaXML
  def output_xml
    @output_xml ||= Nokogiri::XML all_stdout
  end
end

World ArubaXML

Then /the output should be xml/ do
  puts output_xml.inspect
  proc { output_xml }.should_not raise_exception
end

Then /the output xml should contain( a| an| \d+)? (.+)/ do |count, selector|
  count.strip!
  
  if count =~ /^an?$/
    count = 1
  else
    count = count.to_i
  end
  
  output_xml.search(selector).count.should == count
end
