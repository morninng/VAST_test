#!/usr/local/var/rbenv/shims/ruby
require "rubygems"
require "uri"
require "faraday"
require "faraday_middleware"
require "nokogiri"
require "logger"
require 'ostruct'

class Fetcher
    def self.setup( n, c, d, s)
        @@n = n
        @@c = c
        @@d = d
        @@s = s
    end

    #--- Initialize ---
    def initialize
        res = Fetcher::request "http://xp1.zedo.com/jsc/xp2/fns.vast?n=#{@@n}&c=#{@@c}&d=#{@@d}&s=#{@@s}&v=vast2&z=#{rand(9999999)}"
        doc = Nokogiri::XML(res.body)

        #--- get track urls ---
        tracks = OpenStruct.new
        tracks.imp = doc.xpath("//InLine/Impression[@id='IMP']").text.rstrip.lstrip!
        tracks.view = doc.xpath("//InLine/Creatives/Creative/Linear/TrackingEvents/Tracking[@event='creativeView'][1]").text
        tracks.rate = {}
        tracks.rate["0%"] = doc.xpath("//InLine/Creatives/Creative/Linear/TrackingEvents/Tracking[@event='start'][1]").text
        tracks.rate["25%"] = doc.xpath("//InLine/Creatives/Creative/Linear/TrackingEvents/Tracking[@event='firstQuartile'][1]").text
        tracks.rate["50%"] = doc.xpath("//InLine/Creatives/Creative/Linear/TrackingEvents/Tracking[@event='midpoint'][1]").text
        tracks.rate["75%"] = doc.xpath("//InLine/Creatives/Creative/Linear/TrackingEvents/Tracking[@event='thirdQuartile'][1]").text
        tracks.rate["100%"] = doc.xpath("//InLine/Creatives/Creative/Linear/TrackingEvents/Tracking[@event='complete'][1]").text

        #--- call track url ---
        @played = Fetcher::playedRate
        Fetcher::request tracks.imp
        Fetcher::request tracks.view
        Fetcher::request tracks.rate["0%"]
        Fetcher::request tracks.rate["25%"] if @played >= 25
        Fetcher::request tracks.rate["50%"] if @played >= 50
        Fetcher::request tracks.rate["75%"] if @played >= 75
        Fetcher::request tracks.rate["100%"] if @played >= 100
    end

    #--- accessor
    def played
        @played
    end

    private
    #--- Vast Request ---
    def self.request( url )
        uri = URI.parse( url )
        conn = Faraday::Connection.new(:url => uri.scheme+"://"+uri.host) do |builder|
            builder.use Faraday::Request::UrlEncoded
            builder.use Faraday::Response::Logger
            builder.use Faraday::Adapter::NetHttp
            builder.use FaradayMiddleware::FollowRedirects
            builder.adapter Faraday.default_adapter
        end
        conn.headers['User-Agent'] = "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_9_4) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/37.0.2062.94 Safari/537.36"
        conn.request :retry, max:10, interval:0.05
        return conn.get uri.request_uri
    end

    #--- Calc Played Ratio (1 to 100) ---
    def self.playedRate
        x = rand(100)
        return 100 if x > 80  # Completion rate is round 20%
        (( 1.03 ** -x ) * 100 ).to_i
    end

end