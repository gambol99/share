#!/usr/bin/ruby
#
#

require 'rubygems'
require 'optparse'
require 'httparty'
require 'pp'

Meta = {
    :prog    => __FILE__,
    :author  => "Rohith Jayawardene",
    :email   => "gambol99@gmail.com",
    :version => "0.0.1"
}

class URLChecker

    include HTTParty
    #debug_output $stderr

    @options = nil
        @count   = 0

    def initialize( options )

        raise ArgumentError, "you haven't passed any options" unless options
        @options = options
        @count   = @options[:count]

    end

    def process

        stats = { :requests => 0, :success => 0, :total => 0, :avg => 0, :min => 1000000, :max => 0, :timeouts => 0 }
        begin
                
            counter = 0     
            url_length = @options[:url].length + 2
            while counter < @options[:count] or @options[:count] == 0 
                                
                begin

                    start = Time.now
                    stats[:requests] += 1
                    response = self.class.get( @options[:url], { :timeout => @options[:timeout] } )
                    stats[:success]  += 1
                    endtime = Time.now
                    print "%-4d %-14s %#{url_length}s %6.2fms %4d\n" % [ counter, Time.now.strftime("%H:%M:%S.%L"), @options[:url], ( ( endtime - start ) * 1000 ), response.code ]
                    response_time    = ( endtime - start ) * 1000
                    stats[:min]      = response_time if response_time < stats[:min]
                    stats[:max]      = response_time if response_time > stats[:max]
                    stats[:total]    += response_time 

                rescue Timeout::Error => e

                    stats[:timeouts] += 1
                    print "%-4d %-14s %-#{url_length}s the request timed out\n" % [ counter, Time.now.strftime("%H:%M:%S.%L"), @options[:url] ]

                end

                sleep( @options[:interval] )
                counter += 1

            end
 
        rescue SystemExit, Interrupt => e

            puts "..."

        rescue Exception => e

            puts "process: threw an exception: #{e.message}" 
            
        end
        self.print_statistics( stats )

    end

    def print_statistics( stats ) 

        if stats[:success] >= 1 
            requests, success, fails, min, max, avg = stats[:requests], stats[:success], stats[:timeouts], stats[:min], stats[:max], ( stats[:total] / stats[:requests] )
            print "\nrequests: %d, success: %d, fails: %d - avg:%4.2fms, min:%4.2fms, max:%4.2fms\n" % [ requests, success, fails, avg, min, max ] 
        end

    end


end

options = {
    :interval => 0.5,
    :timeout  => 3,
    :show     => false,
    :count    => 0
}
# lets get the options
parser = OptionParser::new do |o|
    o.banner = "Usage: %s -u|--url -t|--timeout secs" % [ Meta[:prog] ]
    o.on( "-u", "--url url",          "the url to be tested"    )          { |arg|  options[:url]      = arg       }
    o.on( "-i", "--interval seconds", "the interval between checks" )      { |arg|  options[:interval] = arg.to_f  }
    o.on( "-c", "--count iterations", "the number of calls to make" )      { |arg|  options[:count]    = arg.to_i  }
    o.on( "-t", "--timeout secs ",    "the timeout per request" )          { |arg|  options[:timeout]  = arg.to_i  }
    o.on( "-o", "--output",           "show the output from the request" ) {        options[:show]     = true }
    o.on( "-V", "--version",          "display the version information"  ) do
        puts "%s written by %s ( %s ) version: %s\n" % [ Meta[:prog], Meta[:author], Meta[:email], Meta[:version] ]
        exit 0
    end
end
parser.parse!

# check we have all the options
mopt = lambda { |msg| 
    puts "%s\nerror: %s" % [ parser, msg ] 
    exit 1 
}
mopt.call "you have not specified a url to call" unless options[:url]
mopt.call "the timeout must numeric" unless options[:timeout].is_a?( Integer) or options[:timeout] > 1

checker = URLChecker::new( options )
checker.process
