//
// Wire
// Copyright (C) 2017 Wire Swiss GmbH
//
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
// GNU General Public License for more details.
//
// You should have received a copy of the GNU General Public License
// along with this program. If not, see http://www.gnu.org/licenses/.
//

import XCTest


class String_ExtremeCombiningCharactersTests: XCTestCase {
    
    static let longDiacriticsTestString = "H͇ͨ̑͐̆̿͑e͏̠̺̘̲͉͍̖r̛̙̔͐e̦͎̠̿ͨ͟'̭͕̺͕̠͙̘̇̐ͫ̂̚s͔̖̖͖̗̘̮͗͊ ̣͚̮̃ͤ̇͘t̖̹͚o̼̩̺̤͖ͣ͘ͅͅ ̮̞͓̤̗t̨̻̘h̻̜͉̜͉͔̆̒̈̋e͙̠̰̺̖̝ͬ͊ͭ͜ ͉̪͍̞̟̀̅̈́̃ͤ̓̀ĉ̣̜̱͚͔̘̗̋ͭͥ̋r̥̗͊̀ͨ̾͋̾ͤa̤̜̟͓̣̗͋͊͜ẓ̪̳̤̯̩y͂́ ̅̀̈́͂҉̙̳̠̦̗̣ǫ̘̠͚͎̲͉ͩͪ͆̔n̝ͣͪ̍ͦ̋͋ͣe̟̳̙̙̺̲͝s̠̖͇̺̞̤.͈̩̠͑̇͌͐̇ͯ̚ͅ ͭͬ́T̳̰͙͒̔́ͤ͋ͩhͨ́̎̓̍͊͑́ẽ̙̠̰͎̺ͩ̂͗͊̎ͧͅ ̖̯ͦ̿̆m̡ͣ͌̚i̢̟͕̖̲ͬͧ̏ͯ̚s̰̼̃̑̈́̋̄͌̈f̺̫͙̃̈́i̘͇̠ͯ̃̿͗̄ͤ͞tͩͥͩ̅̊̈́҉ŝ̢͕͎̤̥͒̑͂.̘̺͝ ̸̤̘T̡͉͚̥̪̥͌h̖̹̟͇͗̔̏̀̆ͤȅ̫ͯ͋͝ ͋͒̏͒̀͐̋r̻͎̩̪̠̱̓͆ͤ̑e͙͖̔b̊̓ȅ̢̻̹͔̺͎͑̍̇̈́l̹̝̒͒͒̀ͣ͝s̵̤̮̠͙̙̰̑̍ͧ̀̉.̺̫̼̼̟̣͐̈́̈́ͩ͘ ̥̫̲͙̊ͩ̍͋T̪̓̽̃̒h̶̥̩͕̮ͅe̥ t̝̩̖̙̖͍̍ͨ̇̿ͧ̕ͅȓ̛̙̞̼̲͍̪̭ö̶͓͍̫́̓̇ͯ̽u̧̪̮̖̜ͥͣ̓̑̎̾b̡̓̒̏l͊̈́͌̄͌҉ẹ̹̹͓ͥ͒ͤͭͥ̑́͝m̆͂̃̚ä̖́̎͛̋ͪk͚͓̲̭̲͔̯ͭ̉ͨ̈͌eͩ̋҉̣̙͎̪rͨͪͭͧs̝̹͚̼̳ͅ.̺͍ ͉͇̗͇̼̆̆̂͢T̂͗͑ͣͩ̌ͭh͂ͤ̾̋̌͒͟e̩͕͈̯͇̋ͤͥͬͫ͌̚ ̙̦̫̝͈̪̈́͐ͦr̭̬̃̂̏͐̅ͪ̿͢ǒ̦̣͂͆̅͗ͮu͔͐̈̌̾͌ͦn̛̼̞̑̓̂ͮ̇̚d͈͇̥ͪ̅ͧ̍ͥ͠ ͔̳̭̜̐͜p̽͑ͭe̟̊͑̍g͖̯͔̘̭͖ͣ̽s̵̒ ̟͖̱i̢̒n̥̄͜ ̷̦̄ͧ̄̆ͩt̿͗̍̍́̋҉̝̻̪̱h͇̥̯̰̟̦̼̐e̲ͯ̀ͮ̐ͭ ̥͖̭͉̦̻̌̉̇ͤ̂̄̃͟s͔ͤͮͩ͊͞q͇̇̾ͯ̿͑̚͟ụ̺̱͍̺̼a̵̩͒ͅr͎̖̱̫̲̻̈́ͪ̔̆̃̄ͦ͟ë̥̪̳͍͙́͛̈ͬ̈́̃͋͟ ̜͎ͤ̓̌͑ͮͦ͝h̸̳̟̯ō̠̮̻̫͈ͨ̑̊l̺̪̻̦͑̿̂́e̗̝̣̝̬̔̓̍ͣ͆̚s͉̣͊̂̚.̇̅̈́ͬ ̢̩̜͓̝̩̆̍T̳̙̮͌ͫͮ̽̆̊h͖̦̻͛̿ͤ̿̉͞é̺̹͖̘̯̙ ̪̳̣̹̱͎̪̒͗o̅̂̂̌ͧ̀n̼̥̖̺̫̼̒̈ͩ͊̌͊e̊̿̓s̱̗͚͉͍̓̄ ̧̝̱ͦ̂̊̑͑ͥ̓w̜̘͇̫͌̈̆h̟̤̟͔͓o̳̊̓̒͗͟ ̯̘̹̙̦̟̯́s̫͙͈̋̀͒ͧͦͬͤ͡ė͈̹̼͕͝e͍̞̮̰̖̾ͫ̆̈́ ̻̱̻̞̭͓̝ͫ̍ͩt̨̙̱͕̹̩̣͌̔͑̈́̀̋ͣh̓͛̃͛̅̃҉̫̳͕i͑̋ͧ̽͡n͖̦͇̟̄ͣg̛̖̰͋̾̅͂͆ͯ̚s̨̲̩̼̣̭̳̈ͯ͊ͥͨ ̝̝ͧ͟d̻͆̾̔ͯͬ̑ǐ̷̳̠̻̲̠ͪ̀͗ͪ̊f̨͕͓̓ͬ̄ͥ̌f̠̿ͤ̓̅e͗̀r̅҉e̞̲̪̼̭͗ͫͥ͐̽͘n̟͇ͥṭ̫̫̟̩̙ͬ͋͒ͥl̘̭̮͚̦͚͖̐͐̎ý͐҉̝̱̦̦.̩̰͓͓̝̆̃ͯ̒͌̊ͅ ̬̜̻̇̓ͤ̒͗ͧ͒T̑̇͆ͫ̽̀͒͏͚͈̠̮͚h͐̌̄̓͗̔̈́ȩ̺͑̌̓̄̑̓y̳͇̼̫̩͔̏ͥ͢'̔̋̇ͨͣ͋͟r̵̻̼̞͇͕̬ͧ͆é͍̘͚̗͉̞̳͆̾̆͂͂ͫ ͍̤̜̓͊̄ͮ̆̎n̘̘̈ô̸t̝͚͍̠ͤ͊ ̢̦̜͔̤f̱̥͚̣̮͔͚͡ő̢̺̾̐n̴͖͓̥̪͔͕̆ͩ̒d͊ ̔͂̂̃̔͛o̲͖ͧ̋ͩͬͫf́ͥ̌͂̕ ̣͙͌ͩͩͮr̡͕̭̞̖̟͇̬̄͗̒ȕ̮̳̯̙͇͙̐l̤̔e̤͂̇ͪ̎̓͐s̘͊̽̕.͎͚͈ͭ̎ͧ̿̌́ͭ͞ ̠̩͖̻̬̋̈A͊͂͂̿͏͓̤̫n̝̄̌̒͠d͉̳̝ͫ̅ͮ͗ͦͦ̀ ͈̯̠̻̹͕͔́̌́̈́̈́̌ͫt̝̜̐̆ͩ̅ͫ̍̓ḧ͚̻́̌̈̐ͨ̽̀e̸ͩ̓͌̓ŷ͎̤̞̅͗ͩ͆͞ͅ ̹̥͓̮̩̲̋̌ͣ̀̈hà̻̺͘v̰̬̮̦̣̭ͣ̂eͬ͗̎͂̔͏͉̳̮̖͉ ̎ͪ҉̤̫̟n̝̞̺̕o̅ͦ͛̑͏̗̲̘̫̲ͅ ̯͎̎̇̍ͩ̔͒ͧ͠ṛ͗̂̊͗͗͡e͎̝͔̞͛ͧ̎͐̀͆̚s̟̘̼̾̈́͂̒̔ͩp̣͔̯͔̹̳̪̎́́é̢̻c̛͍͇͍̺ͪ̔t͓͍̬̮͎͔ ̤̩͍͇̰f̣̖̪̪͋̐̎͑o̩̺̤̭͚͇̓ͬ͘r̦̲̼̝̃̃ͤ̂̍ ̝̞̭ͪ͠ͅṯ͎͖̪̰̜̋ͨ̅̽ͤh̻͍͖eͧ̈́ͭͯͦͯ̔͢ ̻̉̾̚s̫͓̰̈́ͅt̐͏̥̺̹ͅa̡̠̳̬̮̼͑͑͒ͨ͆t̘͔̬̹͚̪̫ͫͭ̇ͬ̚ů͉͉̩̥͗s̼͎̣̼ͦ͌͟ ̪͎͊q̝̣̟̝̻̰͐ͦu̻͓̙͎̜͑̈́̄̄͗ȏ͍̀́͐.͚̟͇̝̳͒̆̀ͅ ͬ̈́̚Y̷̙͖̺̊ͨͣͧͬo̼͓̝͋̂͆ͥ̍uͤ ̶̞̹̦̮̃̔̃̊ċ̺̞̪̰̻̯̫ͧ͜ȃ̯̯̦͕̭̠̄͗̾n̄̋͒̍ ͈̺͚̄͜q̺̘̺̣̲͕͆̽ͫ͌̉ͦu̲̰͎̜̮ͦͯ̀̈͊̃ͣ͘ot͓̭̬͋̽̌̌ͪ̐e̩͇ͣͯ̓̓́ ͇̠̪̙̠̲̆͆̓̈́ͩ͌͘ͅt͚̣͇͖̟̓̏̊̽hͨe͓͔͘ͅm̡̏̆̀͑ͭ,̗ͤ͐ ̱̣̜̞̋̓d͖̞͇̺iͮs̴͉͈̮̭̅ͭ̀ͅạ̟̲̠̝͈͈̒̽̃͑g̯͓͈̪̫̥̲ͣ͡rȅ̢ͬ́̊ȩ͖̋͛͌̎ ̸̯̝͓̦͕̯͉ͭͪͪ̚w̬͖̘̟͇i̷̪̯̺̽ͧt̸͙̲̞͓̥̭̼ͨ̽ͣḧ͓̞̱̗́ͨ̆ ̗͕̪͕̠ͭ̽̿ͨ̚t̘̍̎͂͛ͤ̅h̻͍ͭe̬̼̦̍̊ͦ̎ͪm͕̠̻̘̍̌̾,̱̘̖̭̭́ͪͅ ̄͗͊̓̔ͪg̦̜̬ͨl̯ͣ̀͐͊ͧͅo͕̼ͮ̑ͨr͚̹̽̀̓́̚ï̯ͤͥf͐̒̄̉͑y̳̹̔̎͞ ͕̓ͧ̌ͪ̓͋ơ̹͎͙͒͛̓r̴̦̺̬̫͌͊ͯ̈́̋ ̲̼̊ͬͨͮv̡̔͛̌ͫ̏ḭ͔͍̞ͪ́̿ͯl͊̐̑ͦͬ͛̂҉i̸͇̬̩̲̙͚̥ͧ̈ͦf̦̘̻͇͎͚̈́yͦ̐͏̻͓̟̗ ̹͔̱͚̝̅t̢ͩ͗̎ͅh͈̓̇̈̊͋é̖͓ͯͣmͭ̔̾̊ͪͯ.ͥ ̆͆ͨ́ͬ̄͢A̽̇̑̽ͦ̐ͨ͏͖̥̖̖̪b̦̗ͮͭͥ͢ó̯̘̜͖̮̆u̬͊͐t̴̖̗͎̮̙͇̫ͥ̈́ ̷͔͚̄̓ͬͧͯt̛͒̽̓̈́̅̐̎ḧ̗̮̖̿̉e͉̟͔͖̭̒ͥͣ ̹̣̰̙̹̣̋ͯ͛o̬͙̐ͫ̽̎͜ͅn̷͍̰͚͎̞̼̅̔l̩͈͎̙̮ͬͩ̃ẏ̛̰̭͔́̈ ̢̣̩ț̥̣ẖ̪̦iͪͤ̽͛̍͂n̯̟͙̟͇̪̩ͦͮ̒ͧ͌̏̀g̹͇̔ ̮̯̗͎͈̾̈́̚y̧ͦ̋̇o̴͕̯̜̲̎ͩṳ̳̤̤̬ ̤͓͈̐ͭ̃c̤͚̠̽̆̋ͪȃ̧͎̞̬̞͇ͪ͌ͪͯn͚͈͌̍ͬ͑̔'̳̣͑̈ͭͯͥ̌t̴̬ ̧̲̭͙̝̮́ͭ̀ͧ͆ͧd͓̳͔̟͖̝ͮ̕o̫̦̦̞̬͈̐́̊̆͌ ͓͉͕̤̙i̠͙̬sͯ̓̆̂ ͔̺͉̳̬̹͔͗͊͂ͬ̿i̠̩̖͇̦̾̄̆̔̔̊̾̕g҉̩n̴̿ͧ̌o̞̪̮͓̲͜r̟̯̪ͫ̿͛̓̓̑ͯe̝̩͔͙͖̭̪ͯ̉̌ͥͥ̓ ̴̘͇̮͉̟̦̯̉̒͛ͭ̓̓t̯̥̩̟̱͍͠h̙̮̗̋ͫ͢ȩ͉̠̮ͮ̐͑͋̃̐͊m͈̺̭̺͉̜͎̌̋̒̐̅.̺̜͈̽́̓ ̢̰͍͇̪͍̥͚́ͦ̿B̸̫̜̜̥̩̅̄ͪ̈́̐e̐ͪ̓̓͌̅ͯ͢c̍҉̦̩̯̭a̶͍̲̣̜͕̰͑u̥͍̦̪̥͇̰s̔̈́́ͩ̄ͣ́e̗̯̭̭ ̾ͫ̆ͮ҉͕̦̜t̴̤͔̦h̞͔̜̞̦̲̲͊̔̕e̪͒̿̓͝y̯̺ͮ͂ͩ̚͜ ͓͔͍̏̂̉̀̉͟c̥͖͈̻̞h̹͇̞͕͊͞a̞̳̓̊ͫn̲͔̩̩̼̱̭̐̍̆͋͞g̗̼͚ͩ̓̋ḛ̮̟̩̮̦ͩ̾̅ ͔̞̖̭̰̬̩͛̃͆̍̅ͨͧt̙̺͉͕̫ͤ̏̈́ͫ̐ͭ̚h̡̼̙̥͉͓̓ͨͦ̓̽͐ͦi̯̬̙̹̱̎̿ͦ͟n͉̟̟̽̆̂͗ͣ͟g̢͓͌̆̔͌s̺͔̱ͨ̓̊.̠̰̱̭̦̂̅̍̊ͤ͂͂ ̷̙̓ͤ̎̋̉T̥͖ͯ̌̎̏h̛ͬ̓ͣ̆͌̚̚e̲̖͇̯̋͞y͓ ̷̝̑ͪ̅ͯ́p̷̹̗̩̠ͭ̋͆͛ͫͪ͆u͈̣̺̾š̠̗͉̜̬̪̰h̻̺̤ͯ̆͊ͣ̿͞ ̏͏̯͎̣͖͙t̛̩̘̠̖̳͔̯h̃͑ͦ͐͌̐͛e̥̪͍̔͑̿̚͠ ̷̭͍̘̼̲̈̽ͨͬ̌ḧ́̒͐͐u̒ͧͣ̐̌̐m̖͚aͮ͊̅n̗̐ ̺ͬͫͮ͆͒ͮ̾͟r̡̹̼̙͉͕͂aͭ̂͞c̻͘e͉̲͞ ̨̭̝͚̻̝̅͑̅f͐͊̿̐̈͐҉̟̝o͛r̽͏̩̮͍̮͉ͅw͍̿ͫ͊a̡̦͎̗̟̔͗r͕̬͔̙͔̻̀̒̈́̃̉̈ḑ͈̼̄͐.̘̖̗͎̦̜ͣ͋ͬ͊͢ ̖̯͖̗ͦ͒Ȃ̦̮͗̂ͬ͒͢ṇ̶̤̺̳͉͑d̹̺͇͓̜ͦͭ̅ͩ ̄̈́ẃ͓h̗̞̽i̻̜͕̻̰͍̒́l̦̹͓͎͔̟ͅe͖̥̦̻̊ ṣ̷̠̱͆ò͖̓̿m̍̂̆͠e͆̓͠ ̑͌̽̉m̲̝̒a̳̩͑y̵̱̿͂͑ͣ͆̎͐ ̿̽̿͆̚̚̚͘ś̳͕͍̺͎ěé̬ ̨͖̭̗̯̗̊̈́̆̀ͅt͉ͯͤ̚h̟̠͔͇͈̄e̬͔̰̝̮̪̒́ͭ̄m̡̻̟̦̩̠ͥͅ ̟̰͑͒̂a̤̜̰ͧ̈͡s̜͉͇̟͔ͤ ̺͍̫̤͎̱ͩ͛̓̒̈́͝t̥͓͂̍͒̅͜hͥ̓̂̆́ĕ̠̲̱̹̹̀̾͒͐̚͢ ̰̣͈͛́̔̓ͨͥ̿c̖̜ͦ̆ͭͯͪͤ̔r̻̥͂ͣ̈́̚͢aͯ͒̅̔҉̦z̲̣̏ỷ͒ͯ̓͡ ͍̪͎͚̻̽ͤon̜̰̝̹̮̠ͅĕ͚̰̀͋͋͂s̠̠̼͚͍̍ͥ̌͒̽,̹̼̜̮͂ͤ̀ ͕̬̟̟̬̗̭͛ͤͣ͘ẉ̧̥̘̪͓̲ͧë̢́̐̇́ ̻̗̼̯̗̠͓ͩ̑ͫs̤̯̣̣͉̹̳ͤ̓̑ͣ̿͌̚e̸̥̙͖ͥͣ̚e̴͇͉͉̹̱̍̒ͅ ̰̜̅͋ͣ́g̷̦̗̭̒̊̓̒̑͂ë͔̫̠͖́ͣͦ͌̄̒ͪͅn͉̯̙͑́i̠̹͋ͬͦͪu̒̊͋̊̑ͣ͑͏̭̲s̭̳̤͕̱̃̀.̔ͧ̈́̓̿ͣ͒ ̘̱̩ͫ͒B̖̠͓͈̈̍ͨ͟e̛̙̗̗̿̏͗̒̚c̢̙̮̪͉̗̲̹ͯȁ̡͖̥̰̼ͭ̂͛ù͙̎ͣ̕s̫̼͂͑͠e̴̠̽ ̸̝̦̬̫̰͖̝ͩ̃̅͗̉̅t̩͔̫͚̘ͣh͗ͫ̄́e̡̖̗̩̖͇ ͍̥̖̰̥̓̀͌ͩ̓p̨̞̦̯̈͐ͤe̲̥͕̘̮̗͒o͙͖̖̣͕̓̌́p̷͔̦̻͑ͤ͆ͧ̈́ͬ̓l͇͎̲̹̗͠e̟͈̣͇̗̐̊͌̈́ͤ̀ͬ͟ ͖̒̔͢w̥͠h̷̲̙̙̝o͕̬͔̖̺͓̅̅̉̄̇ ̜̬̽̋͌ͩ̊͋a̤̦͎̭͆ȑ̾̀̈̑̀e̠̒̐̕ ̘͙͚ͥ̿ͩc̬̲͙͇ͪra͇̣͉͇ͩ̏̈́̿͊z̫̯͇͕̲̰̫̓̚y̵̲̯̬̲͍̼̯̌ͤ̊ͯ̒ ̥̪̟͊̓͋e̡͈̲̲̣̲͚nͪͩͣ̏ͧ̇̈́ó̪̪̹̣̭̿͗ͫͫ̈̃u̬̬̩ͦͤ͋͟g̒ͪ̽̆ͭ͑͐ḧ͕͈̜͉̘ͤ̅̃͗̇͢ ͙̤̫ͦ̂̿̌ͯ̚͘t͉͓͍̏͑͂ͦ̌͜ö̲͓́ͩ͗̀ ̩̳͈̼̟ͤͭt̠̤̺͕͖̦̀̐͟h̩̪̥̖̮̠ͭͅḭ͒͗́̐̿ͪ̅n͓̫͇ͮ̑͠k̩̼̥̻͍͈̩̍͑͛͟ ͔͓̝̩͕͕̜͌ͨt̋̏͊̏́h͏̗̖̦͇͎e͊̍͠ŷ̼̫̙̖̜ͅ ̡͍̜̼͙c̳̱̤̦̟̆͂͒a̮ͯ̇ͯn̆̾ͨ͒ͣͫͤ͞ ̬̤̂͋͐̓͝c̝͖̲̭͚̞̮̈ͣͬ͘h̘̮̙̖͟ȁ̐ͪn̳̳̗͙̜g̳̭̹ͅe̶̻̟͓̳̥̭̎̏̎̓ ͌ͧt̖͙̅̒̆ͬͫ́h̤̰̣̮̖̲̱́̑̑̓͐̚͡ė̖̻̘͂ͨ̂ͪ ̵͇̟w͚̜͙͐͒͡o̞̹̘͈̻̳ͫ͒r͔͈͍͔͙̤ͦ̋̂́̚l̰̝̼̹͔̾͑d͕̖̯̒ͮͨ,̓̒̉̈́ͪ͂̔҉̯̞̳̰̲͓ ̸̒̚ạ̛̹̮̼̥̥̲r̸͈͊ͭ̅̌e͎͚̘̣̳̮͑̿ͣ̓̑̌̉͝ ̛t̘̰͚͖ͦ̍ͥͣh͙̳̳͚̤̬̻͛ͫe ̯̘̼͎̆̓o͆ͮ̉n͙̖̓̎̒̽͂̂e̥̤̜̜̪̗̤ͩͮ̏̃sͭ̈́̐̓ͭ̉͆̀ ͈̬̭̲w̞͎̼̳̲̘ͬͣ̌̄h̵̝̪̰͙̲̼ͫ̇̍͛ͧ̔ͣȯ̗̰͈͙̗̰ͅ ̰͖̲̫̺̙d̻̣̝̖͎̔̐͂̆ͪ́o̢̞͔͉.̳̳̣̪̈́̃ͩ"
    
    
    func testThatItPassesEmptyString() {
        XCTAssertEqual("".removingExtremeCombiningCharacters, "")
    }
    
    func testThatItPassesSmallStringWithoutDiacritics() {
        // GIVEN
        let string = "Hello world"
        
        // WHEN & THEN
        XCTAssertEqual(string.removingExtremeCombiningCharacters, string)
    }
    
    func testThatItDoesNotSplitCombinedEmoji() {
        // GIVEN
        let string = "👩‍👩‍👦‍👦"
        
        // WHEN & THEN
        XCTAssertEqual(string.removingExtremeCombiningCharacters, string)
    }
    
    func testThatItPassesSmallExcessiveDiacritics() {
        // GIVEN
        let string = "t͞e̴s͟t"
        
        // WHEN & THEN
        XCTAssertEqual(string.removingExtremeCombiningCharacters, string)
    }
    
    func testThatItPassesStringWithRegularCharacters() {
        // GIVEN
        let string = "Here's to the crazy ones. The misfits. The rebels. The troublemakers."
        
        // WHEN & THEN
        XCTAssertEqual(string.removingExtremeCombiningCharacters, string)
    }
    
    func testThatItPassesLongStringWithRegularCharacters() {
        // GIVEN
        let string = "Here's to the crazy ones. The misfits. The rebels. The troublemakers. The round pegs in the square holes. The ones who see things differently. They're not fond of rules. And they have no respect for the status quo. You can quote them, disagree with them, glorify or vilify them. About the only thing you can't do is ignore them. Because they change things. They push the human race forward. And while some may see them as the crazy ones, we see genius. Because the people who are crazy enough to think they can change the world, are the ones who do."
        
        // WHEN & THEN
        XCTAssertEqual(string.removingExtremeCombiningCharacters, string)
    }
    
    func testThatItPassesExtremeStringWithRegularCharacters() {
        // GIVEN
        let string = "Here's to the crazy ones. The misfits. The rebels. The troublemakers. The round pegs in the square holes. The ones who see things differently. They're not fond of rules. And they have no respect for the status quo. You can quote them, disagree with them, glorify or vilify them. About the only thing you can't do is ignore them. Because they change things. They push the human race forward. And while some may see them as the crazy ones, we see genius. Because the people who are crazy enough to think they can change the world, are the ones who do."
        
        var result = ""
        
        (0...20).forEach { _ in
            result = result + string
        }
        
        // WHEN & THEN
        XCTAssertEqual(result.removingExtremeCombiningCharacters, result)
    }
    
    func testThatItPassesStringWithSomeDiacritics() {
        // GIVEN
        let string = "Falsches Üben von Xylophonmusik quält jeden größeren Zwerg."
        
        // WHEN & THEN
        XCTAssertEqual(string.removingExtremeCombiningCharacters, string)
    }
    
    func testThatItPassesLongStringWithSomeDiacritics() {
        // GIVEN
        let string = "Falsches Üben von Xylophonmusik quält jeden größeren Zwerg. Zwölf Boxkämpfer jagen Viktor quer über den großen Sylter Deich. Polyfon zwitschernd aßen Mäxchens Vögel Rüben, Joghurt und Quark. Schweißgequält zündet Typograf Jakob verflixt öde Pangramme an."
        
        // WHEN & THEN
        XCTAssertEqual(string.removingExtremeCombiningCharacters, string)
    }
    
    func testThatItPassesExtremeStringWithSomeDiacritics() {
        // GIVEN
        let string = "Falsches Üben von Xylophonmusik quält jeden größeren Zwerg. Zwölf Boxkämpfer jagen Viktor quer über den großen Sylter Deich. Polyfon zwitschernd aßen Mäxchens Vögel Rüben, Joghurt und Quark. Schweißgequält zündet Typograf Jakob verflixt öde Pangramme an."
        
        var result = ""
        
        (0...20).forEach { _ in
            result = result + string
        }
        
        // WHEN & THEN
        XCTAssertEqual(result.removingExtremeCombiningCharacters, result)
    }
    
    func testThatItPassesEmojis() {
        // GIVEN
        let string = "😎🎸😎🙌🤘🔜📲"
        
        // WHEN & THEN
        XCTAssertEqual(string.removingExtremeCombiningCharacters, string)
    }
    
    func testThatItPassesMandarin() {
        // GIVEN
        let string = "普通话/普通話"
        
        // WHEN & THEN
        XCTAssertEqual(string.removingExtremeCombiningCharacters, string)
    }
    
    func testThatItPassesCyrillic() {
        // GIVEN
        let string = "Реве та стогне Дніпр широкий, Сердитий вітер завива, Додолу верби гне високі, Горами хвилю підійма."
        
        // WHEN & THEN
        XCTAssertEqual(string.removingExtremeCombiningCharacters, string)
    }
    
    func testThatItPassesArabic() {
        // GIVEN
        let string = "الأشخاص المفضلين"
        
        // WHEN & THEN
        XCTAssertEqual(string.removingExtremeCombiningCharacters, string)
    }
    
    func testThatItPassesTibetianSpecialCase() {
        // GIVEN
        let string = "ཧྐྵྨླྺྼྻྂ"
        // WHEN & THEN
        XCTAssertEqual(string.removingExtremeCombiningCharacters, string)
    }
    
    func testThatItSanitizesExcessiveDiacritics() {
        // GIVEN
        let string = "ť̹̱͉̥̬̪̝ͭ͗͊̕e͇̺̳̦̫̣͕ͫͤ̅s͇͎̟͈̮͎̊̾̌͛ͭ́͜t̗̻̟̙͑ͮ͊ͫ̂"
        
        // WHEN & THEN
        XCTAssertEqual(string.removingExtremeCombiningCharacters, "test̻̟̙")
    }
    
    func testThatItSanitizesExcessiveDiacritics_NSString() {
        // GIVEN
        let string: NSString = "ť̹̱͉̥̬̪̝ͭ͗͊̕e͇̺̳̦̫̣͕ͫͤ̅s͇͎̟͈̮͎̊̾̌͛ͭ́͜t̗̻̟̙͑ͮ͊ͫ̂"
        
        // WHEN & THEN
        XCTAssertEqual(string.removingExtremeCombiningCharacters, "test̻̟̙" as NSString)
    }
    
    func testThatItSanitizesLongStringWithExcessiveDiacritics() {
        // GIVEN
        let string = String_ExtremeCombiningCharactersTests.longDiacriticsTestString
        // WHEN & THEN
        XCTAssertEqual(string.removingExtremeCombiningCharacters, "Here's to the crazy ҉ones. The misfit҉s. The rebels. The troubl҉emake҉rs. The round pegs in t҉he square holes. The ones who see th҉ings differ҉ently҉. They're not fond of rules. And they have ҉no respect for the status quo. You can quote them, disagree with them, glorify or vil҉ify them. About the only thing you can't do is ig҉nore them. Bec҉ause ҉they change things. They push the human race f҉orward. And while some may see them as the cra҉zy ones, we see genius. Because the people who are crazy enough to think they can change the world,҉ are the ones who do.̳̣̪")
    }
    
    func test16kbText() {
        // GIVEN
        let string = try! String(contentsOf: self.fileURL(forResource: "excessive_diacritics", extension: "txt"), encoding: .utf8)

        // WHEN & THEN
        XCTAssertEqual(string.removingExtremeCombiningCharacters.unicodeScalars.count, 6)
    }
    
    func test1MBText() {
        // GIVEN
        let string = try! String(contentsOf: self.fileURL(forResource: "excessive_diacritics", extension: "txt"), encoding: .utf8)
        var result = ""
        
        (0...64).forEach { _ in
            result = result + string
        }
        
        // WHEN & THEN
        XCTAssertTrue(result.removingExtremeCombiningCharacters.unicodeScalars.count < result.unicodeScalars.count)
    }
    
    func testPerformance() {
        // GIVEN
        let string = String_ExtremeCombiningCharactersTests.longDiacriticsTestString
        
        var result = ""
        
        (0...20).forEach { _ in
            result = result + string
        }
        
        // WHEN & THEN
        measure { 
            _ = result.removingExtremeCombiningCharacters
        }
    }
    
    func testValueValidatorForValidString() {
        // GIVEN 
        let initialString = "Hello world"
        var string: AnyObject? = initialString as AnyObject?
        
        // WHEN
        do {
            try ExtremeCombiningCharactersValidator.validateValue(&string)
        }
        catch _ {
            XCTFail()
        }
        
        // THEN
        XCTAssertEqual(string as! String, initialString)
    }
    
    func testValueValidatorForNilString() {
        // GIVEN
        var string: AnyObject? = .none
        
        // WHEN & THEN
        do {
            try ExtremeCombiningCharactersValidator.validateValue(&string)
        }
        catch _ {
            XCTFail()
        }
    }
    
    func testValueValidatorForInvalidString() {
        // GIVEN
        let initialString = "ť̹̱͉̥̬̪̝ͭ͗͊̕e͇̺̳̦̫̣͕ͫͤ̅s͇͎̟͈̮͎̊̾̌͛ͭ́͜t̗̻̟̙͑ͮ͊ͫ̂"
        var string: AnyObject? = initialString as AnyObject?
        
        var thrownError: Error?
        
        // WHEN
        do {
            try ExtremeCombiningCharactersValidator.validateValue(&string)
        }
        catch (let error) {
            thrownError = error
        }
        
        // THEN
        XCTAssertEqual(thrownError! as! ExtremeCombiningCharactersValidationError, ExtremeCombiningCharactersValidationError.containsExtremeCombiningCharacters)
        XCTAssertNotEqual(string as! String, initialString)
        XCTAssertEqual(string as! String, initialString.removingExtremeCombiningCharacters)
    }
}
