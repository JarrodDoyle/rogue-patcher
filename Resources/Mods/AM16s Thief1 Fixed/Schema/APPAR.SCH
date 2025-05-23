//APPARITION



//AT STEADY STATE LEVELS
schema appa0
archetype AI_NONE
mono_loop 10 10
appa0__1 appa0__2 appa0__3 appa0__4 appa0__5 appa0__6
schema_voice vappar 1 atlevelzero
schema_voice vappar 1 atlevelone
schema_voice vappar 1 atleveltwo
schema_voice vappar 1 atlevelthree

//TO LEVEL 1 & 2, BACK
schema appto1
archetype AI_NONE
appa0__1 appa0__2 appa0__3 appa0__4 appa0__5 appa0__6
schema_voice vappar 1 tolevelone
schema_voice vappar 1 toleveltwo
schema_voice vappar 1 backtozero
schema_voice vappar 1 lostcontact


//TO LEVEL THREE
schema appto3
archetype AI_NONE
appa1__1
schema_voice vappar 1 spotplayer
schema_voice vappar 1 tolevelthree
schema_voice vappar 1 reactcharge

//TO LEVEL THREE
//schema appto3
//archetype AI_NONE
//appa3__1 appa3__2 appa3__3
//schema_voice vappar 1 spotplayer


//COMBAT HIT W/HIGH PTS
schema apphhi
archetype AI_NONE
apphhi_1 apphhi_2
schema_voice vappar 1 comhithigh
schema_voice vappar 1 comhitamb

//HIT W/LOW PTS
schema apphlo
archetype AI_NONE
apphlo_1 apphlo_2
schema_voice vappar 1 comhitlow

//DEATH
schema appdies
archetype AI_NONE
appdie
env_tag (Event Death) (CreatureType Apparition)
//schema_voice vappar 1 comdieloud
//schema_voice vappar 1 comdiesoft
