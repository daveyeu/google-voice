# coding: UTF-8
require 'rubygems'
require 'curb'
require 'nokogiri'

module Google
  module Voice
    class Base
      def initialize(email, password)
        @email = email
        @password = password
        login
      end

      def finalize
        logout
      end

      def delete(ids)
        ids = Array(ids)
        fields = [
          Curl::PostField.content('_rnr_se', @_rnr_se),
          Curl::PostField.content('trash', '1')]
        ids.each{|id| fields << Curl::PostField.content('messages', id)}
        @curb.http_post(fields)
        @curb.url = "https://www.google.com/voice/inbox/deleteMessages/"
        @curb.perform
        @curb.response_code
      end

      def archive(ids)
        ids = Array(ids)
        fields = [
          Curl::PostField.content('_rnr_se', @_rnr_se),
          Curl::PostField.content('archive', '1')]
        ids.each{|id| fields << Curl::PostField.content('messages', id)}
        @curb.http_post(fields)
        @curb.url = "https://www.google.com/voice/inbox/archiveMessages/"
        @curb.perform
        @curb.response_code
      end

      def mark(ids, read = true)
        ids = Array(ids)
        fields = [
          Curl::PostField.content('_rnr_se', @_rnr_se),
          Curl::PostField.content('read', read ? '1' : '0')]
        ids.each{|id| fields << Curl::PostField.content('messages', id)}
        @curb.http_post(fields)
        @curb.url = "https://www.google.com/voice/inbox/mark/"
        @curb.perform
        @curb.response_code
      end

      def logged_in?
        return !@_rnr_se.nil?
      end

      def login
        @curb = Curl::Easy.new('https://accounts.google.com/ServiceLoginAuth')
        @curb.headers["User-Agent"] = "Mozilla/5.0 (Macintosh; U; Intel Mac OS X 10.5; en-US; rv:1.9.1.2) Gecko/20090729 Firefox/3.5.2"
        @curb.follow_location = true
        @curb.enable_cookies = true
        # @curb.verbose = true
        @curb.perform

        # Defeat Google's XSRF protection
        @galx = parse_galx_token(@curb.body_str)

        @curb.http_post([
          Curl::PostField.content('continue', 'https://www.google.com/voice'),
          Curl::PostField.content('service', 'grandcentral'),
          Curl::PostField.content('GALX', @galx),
          Curl::PostField.content('Email', @email),
          Curl::PostField.content('Passwd', @password)
        ])
        raise("Could not login to service!") if @curb.response_code != 200

        @_rnr_se = parse_rnr_se_token(@curb.body_str)
        @curb
      end

      def logout
        @curb.url = "https://www.google.com/voice/account/signout"
        @curb.perform
        @curb = nil
      end

      def parse_galx_token(html)
        doc = Nokogiri::HTML::DocumentFragment.parse(html)
        input = doc.css("input[name=GALX]").first
        input ? input["value"] : raise("Could not find GALX token!")
      end

      def parse_rnr_se_token(html)
        doc = Nokogiri::HTML::DocumentFragment.parse(html)
        input = doc.css("input[name=_rnr_se]").first
        input ? input["value"] : raise("Could not find _rnr_se token!")
      end
    end
  end
end
