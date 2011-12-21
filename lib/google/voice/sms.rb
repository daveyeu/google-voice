# coding: UTF-8
require File.join(File.expand_path(File.dirname(__FILE__)), 'base')

GOOGLE_VOICE_SMS_TYPE = 11

module Google
  module Voice
    class Sms < Base
      def sms(number, text)
        @curb.http_post([
          Curl::PostField.content('phoneNumber', number),
          Curl::PostField.content('text', text),
          Curl::PostField.content('_rnr_se', @_rnr_se)
        ])
        @curb.url = "https://www.google.com/voice/sms/send"
        @curb.perform
        @curb.response_code
      end

      # Returns a Hash of telephone number => messages.
      def recent
        @curb.url = "https://www.google.com/voice/inbox/recent/"
        @curb.http_get
        results = {}

        doc = Nokogiri::XML::Document.parse(@curb.body_str)
        html = Nokogiri::HTML::DocumentFragment.parse(doc.to_html)
        html.css("table.gc-message-tbl").each do |table|
          telephone_number = table.css("td.gc-message-tbl-metadata a.gc-message-name-link").inner_html.strip
          messages = table.css("div.gc-message-sms-row").map do |row|
            {}.tap do |message|
              message[:from] = row.css(".gc-message-sms-from").inner_html.strip.gsub(/:$/, "")
              message[:text] = row.css(".gc-message-sms-text").inner_html.strip
              message[:time] = row.css(".gc-message-sms-time").inner_html.strip
            end
          end
          results[telephone_number] = messages
        end

        results
      end
    end
  end
end
