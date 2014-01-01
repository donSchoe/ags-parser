AGS-Parser
==========

Parsing PTS- and BTC-blockchains for angelshares donations in realtime.


Example
=======

Output of the script

 - BTC http://q39.qhor.net/ags/btc.txt
 - PTS http://q39.qhor.net/ags/pts.txt

Requirements
============

 - Ruby 1.9.x (could work with 2.0.x too, untested)
 - Bitcoin daemon running with -txindex=1 -reindex=1
 - Protoshares daemon running with -txindex=1 -reindex=1

Or add txindex=1 to the configuration files. This is needed to parse
transactions within the blockchain.


Usage
=====

To output the transactions to STDOUT:

`$ ruby btc_chain.rb [block=276970]`
`$ ruby pts_chain.rb [block=35450]`

To create a CSV file:

`$ ruby btc_chain.rb [block=276970] > btc_ags.csv &`
`$ ruby pts_chain.rb [block=35450] > pts_ags.csv &`

Note: This script runs in an infinite while-loop and parses the transactions
in real time. Run it from within a screen session or similar to enable continuos
blockchain parsing, e.g. for HTTP output.


Contact
=======

Note: The scripts are licensed under the GPLv3.

Written 2014 by donSchoe, contact me on freenode IRC or send me a Mail to: donSchoe@qhor.net
