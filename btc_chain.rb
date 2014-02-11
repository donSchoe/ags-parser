#!/usr/bin/env ruby
#
# Ruby parser for Angelshares in the Bitcoin Blockchain.
# Usage: $ ruby btc_chain.rb [block=276970] [header=1]
#
# Donations accepted:
# - BTC 1Bzc7PatbRzXz6EAmvSuBuoWED96qy3zgc
# - PTS PcDLYukq5RtKyRCeC1Gv5VhAJh88ykzfka
#
# Copyright (C) 2014 donSchoe <donschoe@qhor.net>
#
# This program is free software: you can redistribute it and/or modify it under
# the terms of the GNU General Public License as published by the Free Software
# Foundation, either version 3 of the License, or (at your option) any later
# version.
#
# This program is distributed in the hope that it will be useful, but WITHOUT
# ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
# FOR A PARTICULAR PURPOSE. See the GNU General Public License for more
# details.
#
# You should have received a copy of the GNU General Public License along with
# this program. If not, see <http://www.gnu.org/licenses/>.

require 'net/http'
require 'open-uri'
require 'json'

################################################################################

# BTC daemon connection
@connection = 'http://user:password@127.0.0.1:8332'

# Enable/Disable debugging output.
@debug = true

# Enable/Display daily summaries and output clean CSV only.
@clean_csv = true

################################################################################

require 'net/http'
require 'uri'
require 'json'
 
class BitcoinRPC
  def initialize(service_url)
    @uri = URI.parse(service_url)
  end
 
  def method_missing(name, *args)
    post_body = { 'method' => name, 'params' => args, 'id' => 'jsonrpc' }.to_json
    resp = JSON.parse( http_post_request(post_body) )
    raise JSONRPCError, resp['error'] if resp['error']
    resp['result']
  end
 
  def http_post_request(post_body)
    http    = Net::HTTP.new(@uri.host, @uri.port)
    request = Net::HTTP::Post.new(@uri.request_uri)
    request.basic_auth @uri.user, @uri.password
    request.content_type = 'application/json'
    request.body = post_body
    http.request(request).body
  end
 
  class JSONRPCError < RuntimeError; end
end

@rpc = BitcoinRPC.new(@connection)

# gets block number (height) to start the script at
if ARGV[0].nil?
  # default
  blockstrt = 276970
else
  # from args
  blockstrt = ARGV[0].to_i
end

# initializes global args
@sum = 0.0
@ags = 0
@day = 1388620800
i=0

################################################################################

# script output start (CSV header)
$stdout.sync = true
$stderr.sync = true

if ARGV[1].nil?
  # default
  header = 1
else
  # from args
  header = ARGV[1].to_i
end

if header > 0
  puts "\"BLOCK\";\"DATETIME\";\"TXBITS\";\"SENDER\";\"DONATION[BTC]\";\"DAYSUM[BTC]\";\"DAYRATE[AGS/BTC]\""
end

# parses given transactions
def parse_tx(hi=nil, time=nil, tx)

  # block to catch huge transactions over size limit
  begin

    # gets transaction JSON data
    jsontx = @rpc.getrawtransaction(tx, 1)

    # check every transaction output
    jsontx['vout'].each do |vout|

      # gets recieving address and value
      address = vout["scriptPubKey"]["addresses"]
      value = vout["value"]

      # checks addresses for being angelshares donation address
      if not address.nil?
        if address.include? '1ANGELwQwWxMmbdaSWhWLqBEtPTkWb8uDc'

          # display daily summary and split CSV data in days
          while (time.to_i > @day.to_i) do

            # disable summary output for clean CSV files
            if not @clean_csv
              puts "+++++ Day Total: #{@sum.round(8)} BTC (#{@ags.round(8)} AGS/BTC) +++++"
              puts ""
              puts "+++++ New Day : #{Time.at(@day.to_i).utc} +++++"
              puts "\"BLOCK\";\"DATETIME\";\"TXBITS\";\"SENDER\";\"DONATION[BTC]\";\"DAYSUM[BTC]\";\"DAYRATE[AGS/BTC]\""
            end

            # reset BTC sum and sitch day
            @sum = 0.0
            @day += 86400
          end

          # gets UTC timestamp
          stamp = Time.at(time.to_i).utc

          # checks each input for sender addresses
          senderhash = Hash.new
          jsontx['vin'].each do |vin|

            # parses the sender from input txid and n
            sendertx = vin['txid']
            sendernn = vin['vout']

            # block to catch huge transactions over size limit
            begin

              # gets transaction JSON data
              senderjsontx = @rpc.getrawtransaction(sendertx, 1)

              # scan sender transaction for sender address
              senderjsontx['vout'].each do |sendervout|
                if sendervout['n'].eql? sendernn

                  # gets angelshares sender address and input value
                  if senderhash[sendervout['scriptPubKey']['addresses'].first.to_s].nil?
                    senderhash[sendervout['scriptPubKey']['addresses'].first.to_s] = sendervout['value'].to_f
                  else
                    senderhash[sendervout['scriptPubKey']['addresses'].first.to_s] += sendervout['value'].to_f
                  end
                end
              end

            # catches transactions which are too big to parse and uses web API
            rescue Errno::E2BIG

              if @debug
                $stderr.puts "!!!WARNG TX TOO BIG TO PARSE #{sendertx}"
              end

              # uses blockchain info to get tx JSON data
              senderjsontx = open("https://blockchain.info/tx/#{sendertx}?format=json").read
              senderjsontx = JSON.parse(senderjsontx)

              # scan sender transaction for sender address
              senderjsontx['out'].each do |sendervout|
                if sendervout['n'].eql? sendernn

                  # gets angelshares sender address and input value
                  if senderhash[sendervout['addr'].to_s].nil?
                    senderhash[sendervout['addr'].to_s] = (sendervout['value'].to_f / 100000000.0)
                  else
                    senderhash[sendervout['addr'].to_s] += (sendervout['value'].to_f / 100000000.0)
                  end
                end
              end
            end
          end

          # gets donation value by each input address of the transaction
          outval = value
          presum = 0.0
          sumval = 0.0
          senderhash.each do |key, inval|
            printval = 0.0
            sumval += inval
            if sumval <= outval
              printval = inval
            else
              printval = outval - presum
            end

            # prints donation stats if input value is above 0
            if printval > 0

              # sums up donated BTC value
              @sum += printval

              # calculates current angelshares ratio
              @ags = 5000.0 / @sum

              txbits = tx
              puts "\"" + hi.to_s + "\";\"" + stamp.to_s + "\";\"" + txbits.to_s + "\";\"" + key.to_s + "\";\"" + printval.round(8).to_s + "\";\"" + @sum.round(8).to_s + "\";\"" + @ags.round(8).to_s + "\""
            end
            presum += inval
          end
        end
      else

        # debugging warning: transaction without output address
        if @debug
          $stderr.puts "!!!WARNG ADDRESS EMPTY #{vout.to_s}"
        end
      end
    end

  # catches transactions which are too big to parse and uses web API
  rescue Errno::E2BIG

    if @debug
      $stderr.puts "!!!WARNG TX TOO BIG TO PARSE #{tx}"
    end

    # uses blockchain info to get tx JSON data
    jsontx = open("https://blockchain.info/tx/#{tx}?format=json").read
    jsontx = JSON.parse(jsontx)

    # check every transaction output
    jsontx['out'].each do |vout|

      # gets recieving address and value
      address = vout["addr"]
      value = vout["value"]

      # checks addresses for being angelshares donation address
      if not address.nil?
        if address.include? '1ANGELwQwWxMmbdaSWhWLqBEtPTkWb8uDc'

          # display daily summary and split CSV data in days
          while (time.to_i > @day.to_i) do

            # disable summary output for clean CSV files
            if not @clean_csv
              puts "+++++ Day Total: #{@sum.round(8)} BTC (#{@ags.round(8)} AGS/BTC) +++++"
              puts ""
              puts "+++++ New Day : #{Time.at(@day.to_i).utc} +++++"
              puts "\"BLOCK\";\"DATETIME\";\"TXBITS\";\"SENDER\";\"DONATION[BTC]\";\"DAYSUM[BTC]\";\"DAYRATE[AGS/BTC]\""
            end

            # reset BTC sum and sitch day
            @sum = 0.0
            @day += 86400
          end

          # gets UTC timestamp
          stamp = Time.at(time.to_i).utc

          # checks each input for sender addresses
          senderhash = Hash.new
          jsontx['inputs'].each do |vin|

            # parses the sender from input
            senderadr = vin['addr']
            senderval = vin['value']

            # gets angelshares sender address and input value
            if senderhash[sendervout[senderadr].first.to_s].nil?
              senderhash[sendervout[senderadr].first.to_s] = (senderval.to_f / 100000000.0)
            else
              senderhash[sendervout[senderadr].first.to_s] += (senderval.to_f / 100000000.0)
            end
          end

          # gets donation value by each input address of the transaction
          outval = value
          presum = 0.0
          sumval = 0.0
          senderhash.each do |key, inval|
            printval = 0.0
            sumval += inval
            if sumval <= outval
              printval = inval
            else
              printval = outval - presum
            end

            # prints donation stats if input value is above 0
            if printval > 0

              # sums up donated BTC value
              @sum += printval

              # calculates current angelshares ratio
              @ags = 5000.0 / @sum

              txbits = tx[0..8]
              puts "\"" + hi.to_s + "\";\"" + stamp.to_s + "\";\"" + txbits.to_s + "\";\"" + key.to_s + "\";\"" + printval.round(8).to_s + "\";\"" + @sum.round(8).to_s + "\";\"" + @ags.round(8).to_s + "\""
            end
            presum += inval
          end
        end
      else

        # debugging warning: transaction without output address
        if @debug
          $stderr.puts "!!!WARNG ADDRESS EMPTY #{vout.to_s}"
        end
      end
    end
  end
end

# starts parsing the blockchain in infinite loop
while true do

  # debugging output: loop number & start block height
  if @debug
    $stderr.puts "---DEBUG LOOP #{i}"
    $stderr.puts "---DEBUG BLOCK #{blockstrt}"
  end

  # gets current block height
  blockhigh = @rpc.getblockcount

  #reads every block by block
  (blockstrt.to_i..blockhigh.to_i).each do |hi|
    if @debug
      $stderr.puts "---DEBUG BLOCK #{hi}"
    end

    # gets block hash string
    blockhash = @rpc.getblockhash(hi)

    # gets JSON block data
    blockinfo = @rpc.getblock(blockhash)

    # gets block transactions & time
    transactions = blockinfo['tx']
    time = blockinfo['time']

    # parses transactions ...
    if not transactions.nil?
      if not transactions.size <= 1
        transactions.each do |tx|

          # ... one by one
          parse_tx(hi, time, tx)
        end
      else

        # ... only one available
        parse_tx(hi, time, transactions.first)
      end
    else

      # debugging warning: block without transactions
      if @debug
        $stderr.puts "!!!WARNG NO TRANSACTIONS IN BLOCK #{hi}"
      end
    end
  end

  # debugging output: current loop summary
  if @debug
    $stderr.puts "---DEBUG SUM #{@sum.round(8)}"
    $stderr.puts "---DEBUG VALUE #{@ags.round(8)}"
  end

  # resets starting block height to next unparsed block
  blockstrt = blockhigh.to_i + 1
  i += 1

  # wait for new blocks to appear
  sleep(600)
end
