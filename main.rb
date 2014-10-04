#!/usr/local/var/rbenv/shims/ruby
require './fetcher.rb'
require 'time'
require 'thread'
require 'logger'

#--- configuration ---
total_imp = 100000
end_at = Time.parse( "2014/10/31 10:00:00" )
weights = [
#   0    1    2    3    4    5    6    7    8    9    10   11 (hour)
    0.9, 0.3, 0.2, 0.2, 0.2, 0.2, 0.3, 0.4, 0.6, 1.0, 0.9, 0.8, # AM
    1.0, 0.9, 0.8, 0.7, 0.7, 0.8, 1.0, 0.9, 0.8, 0.8, 1.3, 1.6  # PM
]
Fetcher.setup(2117, 437, 76, 0) # Ad Call n, c, d, s

#--- loop ---
log = Logger.new('./fetcher.log', 'daily')
log.level = Logger::DEBUG
total_weight = weights.inject(0){ |sum, w| sum += w }
workers = []
while Time.now < end_at do
    t = Thread.new do
        begin
            f = Fetcher.new
            log.debug "played #{f.played}%"
        rescue ThreadError => e
            log.fatal "Thread Error : #{e.to_s}"
        rescue => e
            log.fatal "Standard Error : #{e.to_s}"
        end
    end
    workers.push( t )
    hour = Time.now.hour
    imp_per_hour = ( weights[hour] / total_weight * total_imp ).to_i
    imp_per_sec = imp_per_hour / 3600.0
    interval = 1.0 / imp_per_sec
    t0 = Time.now.to_f; sleep interval; t1 = Time.now.to_f
    log.debug "interval #{t1 - t0}"
end
workers.map(&:join)
log.info "All Finished"
