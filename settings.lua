---------------------------------------------
-----------  RANDOMIZER SETTINGS  -----------
---------------------------------------------
----------  Change the values of  -----------
-----------  the variables below  -----------
------------  before generating  ------------
---------------------------------------------

FILE_NAME = "GUEST"     
                        --[[
                            The file name that appears on the select screen
                            Check charactertable.lua for a list of valid characters
                            Must be 9 characters or fewer
                        --]]

RANDOMIZE_MAKEUP = true 
                        --[[
                            Randomize the default look of your Helirin

                            Note that if you're wearing bonuses that you do not have unlocked,
                            changing makeup may lock you out of wearing it until collected
                        --]]

WIN_CONDITION = "birds" 
                        --[[
                            The win condition for the randomizer

                            OPTIONS

                            "birds"          Collect all birds
                            "bonuses"        Collect all bonuses (birds and cosmetic)
                            "levels"         Complete all available levels
                            "all"            Complete all available levels and collect all bonuses

                            Putting anything else here will default the win condition to "birds"
                        --]]

INCLUDE_BONUS_LEVELS = false     
                        --[[
                            Whether or not to include the last three bonus levels
                            Note that these levels do not include bonus pickups
                            Must be true or false
                        --]]

INCLUDE_TRAINING_LEVELS = false  
                        --[[
                            Whether or not to include the training levels
                            Note that these levels do not include bonus pickups
                            Must be true or false
                        --]]

SHUFFLE_BONUSES = true      
                        --[[ 
                            Whether the bonus pickups in each level are shuffled
                            Note that there are no bonus pickups in the training or bonus levels
                            Must be true or false
                        --]]

LEVEL_ORDER = "close"       
                        --[[ 
                            How the randomizer chooses a level to unlock after completing another
                            This methodology is also used to choose the starting level
                                
                            OPTIONS
                                
                            "random"        Completely random
                            "unshuffled"    Play the levels in order
                            "close"         Levels will unlock randomly, but favour earlier uncompleted levels

                            You can replace this option with a number (no quotations), and the next unlocked
                            level will be chosen randomly from the N earliest uncleared levels
                                                
                            Example: the default "close" value is 6, so if you've completed level
                            4, the level you unlock will be one of 1, 2, 3, 5, 6, or 7
                        --]]