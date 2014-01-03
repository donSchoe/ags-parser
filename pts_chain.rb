#!/usr/bin/env ruby
#
# Ruby parser for Angelshares in the Protoshares Blockchain.
# Usage: $ ruby pts_chain.rb [block=35450]
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

# Point this path to your PTS daemon!
@path = '/path/to/protosharesd'

# Enable/Disable debugging output.
@debug = false

################################################################################

# gets block number (height) to start the script at
if ARGV[0].nil?
  # default
  blockstrt = 35450
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
puts "BLOCK;DATETIME;SENDER;DONATION[PTS];SUM[PTS];RATE[AGS/PTS];EXPECTED[AGS]"

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
        if address.include? 'PaNGELmZgzRQCKeEKM6ifgTqNkC4ceiAWw'

          # display daily summary and split CSV data in days
          while (time.to_i > @day.to_i) do
            puts "+++++ Day Total: #{@sum} PTS (#{@ags} AGS/PTS) +++++"
            puts ""
            puts "+++++ New Day : #{Time.at(@day.to_i).utc} +++++"
            puts "BLOCK;DATETIME;SENDER;DONATION[PTS];SUM[PTS];RATE[AGS/PTS];EXPECTED[AGS]"

            # reset PTS sum and sitch day
            @sum = 0.0
            @day += 86400
          end

          # sums up donated PTS value
          @sum += value

          # gets UTC timestamp
          stamp = Time.at(time.to_i).utc

          # calculates current angelshares ratio
          @ags = 5000.0 / @sum

          # calculates expected angelshares
          expected = value * @ags

          # parses the sender from input txid and n
          sendertx = jsontx['vin'].first['txid']
          sendernn = jsontx['vin'].first['vout']

          # gets raw transaction of the sender
          senderrawtx = `#{@path} getrawtransaction #{sendertx}`

          # gets transaction JSON data of the sender
          senderjsontx = `#{@path} decoderawtransaction #{senderrawtx}`
          senderjsontx = JSON.parse(senderjsontx)
          sender = 'unknown'

          # scan sender transaction for sender address
          senderjsontx["vout"].each do |sendervout|
            if sendervout['n'].eql? sendernn

              # gets angelshares sender address
              # @TODO https://github.com/donSchoe/ags-parser/issues/3
              sender = sendervout['scriptPubKey']['addresses'].first
            end
          end

          # displays current transaction details
          puts hi.to_s + ';' + stamp.to_s + ';' + sender.to_s + ';' + value.to_s + ';' + @sum.to_s + ';' + @ags.to_s + ';' + expected.to_s
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
