TiTOLpeli

main.gd handles the starting of the game and houses meta-level information like teams_info and cities.

game.gd changed to jyväskylä.gd to make game logic city specific. 
This allows us to make completely different games for each city.

HUD is handled game specifically. 
For example, main.gd adds the teams to Jyväskylä/HUD/TeamsList and gives basic formatting, but Jyväskylä.gd reformats the content if necessary.
