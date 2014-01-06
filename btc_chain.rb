#!/usr/bin/env ruby
#
# Ruby parser for Angelshares in the Bitcoin Blockchain.
# Usage: $ ruby btc_chain.rb [block=276970]
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

require 'json'

################################################################################

# Point this path to your BTC daemon!
@path = '/path/to/bitcoind'

# Enable/Disable debugging output.
@debug = false

# Enable/Display daily summaries and output clean CSV only.
@clean_csv = true

################################################################################

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
puts "\"BLOCK\";\"DATETIME\";\"TXBITS\";\"SENDER\";\"DONATION[BTC]\";\"DAYSUM[BTC]\";\"DAYRATE[AGS/BTC]\""

# parses given transactions
def parse_tx(hi=nil, time=nil, tx)
  begin

    # gets raw transaction
    rawtx = `#{@path} getrawtransaction #{tx}`

    # gets transaction JSON data
    jsontx = `#{@path} decoderawtransaction #{rawtx}`
    jsontx = JSON.parse(jsontx)

    # check every transaction output
    jsontx["vout"].each do |vout|

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
              puts "+++++ Day Total: #{@sum} BTC (#{@ags} AGS/BTC) +++++"
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

            # gets raw transaction of the sender
            senderrawtx = `#{@path} getrawtransaction #{sendertx}`

            # gets transaction JSON data of the sender
            senderjsontx = `#{@path} decoderawtransaction #{senderrawtx}`
            senderjsontx = JSON.parse(senderjsontx)

            # scan sender transaction for sender address
            senderjsontx["vout"].each do |sendervout|
              if sendervout['n'].eql? sendernn

                # gets angelshares sender address and input value
                if senderhash[sendervout['scriptPubKey']['addresses'].first.to_s].nil?
                  senderhash[sendervout['scriptPubKey']['addresses'].first.to_s] = sendervout['value'].to_f
                else
                  senderhash[sendervout['scriptPubKey']['addresses'].first.to_s] += sendervout['value'].to_f
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

            # sums up donated BTC value
            @sum += printval

            # calculates current angelshares ratio
            @ags = 5000.0 / @sum

            # prints donation stats if input value is above 0
            if printval > 0
              txbits = tx[0..8]
              puts "\"" + hi.to_s + "\";\"" + stamp.to_s + "\";\"" + txbits.to_s + "\";\"" + key.to_s + "\";\"" + printval.round(8).to_s + "\";\"" + @sum.round(8).to_s + "\";\"" + @ags.round(8).to_s + "\""
            end
            presum += inval
          end
        end
      else

        # debugging warning: transaction without output address
        if @debug
          puts "!!!WARNG ADDRESS EMPTY #{vout.to_s}"
        end
      end
    end

  # catches transactions which are too big to parse
  # @TODO https://github.com/donSchoe/ags-parser/issues/2
  rescue Errno::E2BIG
    if @debug
      puts "!!!ERROR TX TOO BIG TO PARSE #{tx}"
    end
  end
end

# starts parsing the blockchain in infinite loop
while true do

  # debugging output: loop number & start block height
  if @debug
    puts "---DEBUG LOOP #{i}"
    puts "---DEBUG BLOCK #{blockstrt}"
  end

  # gets current block height
  blockhigh = `#{@path} getblockcount`

  #reads every block by block
  (blockstrt.to_i..blockhigh.to_i).each do |hi|

    # gets block hash string
    blockhash = `#{@path} getblockhash #{hi}`

    # gets JSON block data
    blockinfo = `#{@path} getblock #{blockhash}`

    # gets block transactions & time
    transactions = JSON.parse(blockinfo)['tx']
    time = JSON.parse(blockinfo)['time']

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
        puts "!!!WARNG NO TRANSACTIONS IN BLOCK #{hi}"
      end
    end
  end

  # debugging output: current loop summary
  if @debug
    puts "---DEBUG SUM #{@sum}"
    puts "---DEBUG VALUE #{@ags}"
  end

  # resets starting block height to next unparsed block
  blockstrt = blockhigh.to_i + 1
  i += 1

  # wait for new blocks to appear
  sleep(600)
end
