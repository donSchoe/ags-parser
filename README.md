AGS-Parser
==========

Parsing PTS- and BTC-blockchains for angelshares donations in realtime and
providing an API in CSV and JSON.


Example
-------

Output of the script

 - BTC http://q39.qhor.net/ags/4/btc.csv.txt
 - PTS http://q39.qhor.net/ags/4/pts.csv.txt
 - AGS http://q39.qhor.net/ags/3/balances.json

See my bot parsing the output on #angleshares at Freenode. Type: .ags

 - http://de.irc2go.com/webchat/?net=freenode&room=angelshares&nick=github1337

Sites using my API:

 - http://agsexplorer.com
 - http://joelooney.org/ags/


Requirements
------------

For the BTC-/PTS-blockchain-parser:
 - Ruby 1.9.x or 2.0.x
 - Bitcoin daemon running with -txindex=1 -reindex=1
 - Protoshares daemon running with -txindex=1 -reindex=1

Or add txindex=1 to the configuration files. This is needed to parse
transactions within the blockchain.

For the AGS-balance tool:

 - Ruby 1.9.x or 2.0.x
 - CSV data from the BTC-/PTS-scripts above

 You can use the example-links above.


Usage
-----

Open the BTC-/PTS-script to modify `@path`, `@debug` and `@clean_csv` settings.
Then run the script.

To output the transactions to STDOUT:

`$ ruby btc_chain.rb [block=276970] [header=1]`

`$ ruby pts_chain.rb [block=35450] [header=1]`

To create a CSV file:

`$ ruby btc_chain.rb [block=276970] > btc_ags.csv &`

`$ ruby pts_chain.rb [block=35450] > pts_ags.csv &`

To update a CSV file from specific block:

`$ ruby btc_chain.rb [block=277000] [header=0] >> btc_ags.csv &`

`$ ruby pts_chain.rb [block=36000] [header=0] >> pts_ags.csv &`

Note: This script runs in an infinite while-loop and parses the transactions
in real time. Run it from within a screen session or similar to enable continuos
blockchain parsing, e.g. for HTTP output.

Afterwards you can use the AGS-script to generate a JSON array of balances.

To output the transactions to STDOUT:

`$ ruby ags_balance.rb [brief=0]`

To create a JSON file:

`$ ruby ags_balance.rb > ags_balance.json`

To create a brief JSON file:

`$ ruby ags_balance.rb [brief=1] > ags_balance.json`

This script only needs updating once a day.


Contact
-------

Note: The scripts are licensed under the GPLv3. You should have received a copy
of the GNU General Public License along with this program. If not, see:
  http://www.gnu.org/licenses/

Written 2014 by donSchoe, contact me on freenode IRC or send me a Mail to:
  donSchoe@qhor.net

Feedback thread:

 - https://bitsharestalk.org/index.php?topic=1853.0

Donations accepted:

 - BTC 1Bzc7PatbRzXz6EAmvSuBuoWED96qy3zgc
 - PTS PcDLYukq5RtKyRCeC1Gv5VhAJh88ykzfka
