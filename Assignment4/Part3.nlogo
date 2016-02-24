; UVA/VU - Multi-Agent Systems
; Lecturers: T. Bosse & M.C.A. Klein
; Lab assistants: D. Formolo & L. Medeiros

;; Assignment 4.2
;; Authors: David van Erkelens (10264019> <me@davidvanerkelens.nl>
;;          Ysbrand Galama (10262067) <y.galama@hotmail.com>

; --- Assignment 4.2 & 4.3 - Template ---
; Please use this template as a basis for the code to generate the behaviour of your team of vacuum cleaners.
; However, feel free to extend this with any variable or method you think is necessary.


; --- Settable variables ---
; The following settable variables are given as part of the 'Interface' (hence, these variables do not need to be declared in the code):
;
; 1) dirt_pct: this variable represents the percentage of dirty cells in the environment.
;
; 2) num_agents: number of vacuum cleaner agents in the simularion.
;
; 3) vision_radius: distance (in terms of number of cells) that the agents can 'see'
; For instance, if this radius is 3, then agents will be able to observe dirt in a cell that is 3 cells away from their own location.


; --- Global variables ---
; The following global variables are given.
;
; 1) total_dirty: this variable represents the amount of dirty cells in the environment.
; 2) time: the total simulation time.
globals [total_dirty time colors]


; --- Agents ---
; The following types of agent (called 'breeds' in NetLogo) are given.
;
; 1) vacuums: vacuum cleaner agents.
breed [vacuums vacuum]
breed [radii radius]

; --- Local variables ---
; The following local variables are given.
;
; 1) beliefs: the agent's belief base about locations that contain dirt
; 2) desire: the agent's current desire
; 3) intention: the agent's current intention
; 4) own_color: the agent's belief about its own target color
; 5) other_colors: the agent's belief about the target colors of other agents
; 6) outgoing_messages: list of messages sent by the agent to other agents
; 7) incoming_messages: list of messages received by the agent from other agents
vacuums-own [beliefs desire intention outgoing_messages incoming_messages]


; --- Setup ---
to setup
  clear-all
  set time 0
  setup-colors
  setup-patches
  setup-vacuums
  setup-ticks
end


; --- Main processing cycle ---
to go
  ; This method executes the main processing cycle of an agent.
  ; For Assignment 4.1, this involves updating desires, beliefs and intentions, and executing actions (and advancing the tick counter).
  update-beliefs
  update-desires
  update-intentions
  execute-actions
  send-messages
  tick
end


; --- Setup patches ---
to setup-patches
  ; In this method you may create the environment (patches), using colors to define cells with various types of dirt.
  ask patches [
    ifelse random 100 < dirt_pct [
      set pcolor (item (random num_agents) colors)
    ]
    [
      set pcolor white
    ]
  ]
end


; --- Setup vacuums ---
to setup-vacuums
  ; In this method you may create the vacuum cleaner agents.
  create-vacuums num_agents [
    setxy random-pxcor random-pycor
    set shape "airplane"
  ]
  create-radii num_agents [
    set shape "circle"
    set size 2 * vision_radius
  ]

  let i 0
  while [i < num_agents]
  [

    ask vacuum i [
      set color grey
    ]
    ask radius (i + num_agents) [
      let c grey
      set color lput 90 extract-rgb c
      setxy [xcor] of vacuum i [ycor] of vacuum i
      create-link-with vacuum i
    ]
    set i i + 1
  ]
  ask vacuums [
    set outgoing_messages []
    set incoming_messages []

    let color-space []
    foreach colors [
      let q []
      set q lput ? q
      set q lput 0 q
      set color-space lput q color-space
    ]

    set beliefs []
    set beliefs lput color-space beliefs
    set beliefs lput [] beliefs
    set beliefs lput grey beliefs
    set beliefs lput colors beliefs
    set beliefs lput 1 beliefs
    set beliefs lput [] beliefs
  ]
end


; --- Setup ticks ---
to setup-ticks
  ; In this method you may start the tick counter.
  reset-ticks
end

to setup-colors
  let i 0
  let all_colors [cyan blue pink yellow red green brown]
  set colors []
  while [i < num_agents] [
    set colors lput item i all_colors colors
    set i i + 1
  ]
end


; --- Update desires ---
to update-desires
  ; You should update your agent's desires here.
  ; Keep in mind that now you have more than one agent.
  ask vacuums [
   let own-color item 2 beliefs
   let dirt-left item 4 beliefs

   ifelse (dirt-left <= 0) [
     set desire "stop and rest"
   ] [
     ifelse (not in colors own-color) [
       set desire "find color"
     ] [
       set desire "clean the dirt"
     ]
   ]
  ]
end


; --- Update beliefs ---
to update-beliefs
 ; You should update your agent's beliefs here.
 ; Please remember that you should use this method whenever your agents changes its position.
 ask vacuums [
   let color-choice item 0 beliefs
   let dirty-locations item 1 beliefs
   let own-color item 2 beliefs
   let other-colors item 3 beliefs
   let dirt-left item 4 beliefs
   let other-locations item 5 beliefs

   foreach incoming_messages [
     ifelse (item 0 ? = "color-set") [
       set other-colors remove item 1 ? other-colors
     ] [
       if (not in dirty-locations ?) [
         set dirty-locations lput ? dirty-locations
       ]
     ]
   ]



   set dirty-locations sort-by [
     distancexy item 0 ?1 item 1 ?1 < distancexy item 0 ?2 item 1 ?2
   ] dirty-locations

   set beliefs []
   set beliefs lput color-choice beliefs
   set beliefs lput dirty-locations beliefs
   set beliefs lput own-color beliefs
   set beliefs lput other-colors beliefs
   set beliefs lput dirt-left beliefs
   set beliefs lput other-locations beliefs
 ]
end


; --- Update intentions ---
to update-intentions
  ; You should update your agent's intentions here.
  ask vacuums
  [
    let color-choice item 0 beliefs
    let dirty-locations item 1 beliefs
    let own-color item 2 beliefs
    let other-colors item 3 beliefs
    let dirt-left item 4 beliefs
    let other-locations item 5 beliefs

    ifelse (intention != "look-around") [
      set intention "look-around"
    ] [
      ifelse (desire = "clean the dirt")
      [
        ifelse (dirt-left = 0)
        [
          set intention "stop"
        ]
        [
          ifelse (length dirty-locations = 0)
          [
            set intention "move"
          ]
          [
            let l item 0 dirty-locations
            let x item 0 l
            let y item 1 l
            ifelse (x = xcor and y = ycor)
            [
              if ([pcolor] of patch x y = color)
              [
                set intention "clean"
              ]
            ]
            [
              ifelse (heading = (towardsxy x y))
              [
                set intention "moveto"
              ]
              [
                set intention "turnto"
              ]
            ]
          ]
        ]
      ] [
        ifelse (desire = "find color") [
          ifelse(length other-colors = 1) [
            set intention "choose"
            set own-color item 0 other-colors
          ] [
            let found false
            foreach color-choice [
              if (not found and item 1 ? >= color-thresh and in other-colors item 0 ?) [
                set intention "choose"
                set own-color item 0 ?
                set found true
                ask vacuums [
                  ; because the update in messages comes to late, here is a short-cut to let the other
                  ;  agents know the choice immediatly
                  let color-choice2 item 0 beliefs
                  let dirty-locations2 item 1 beliefs
                  let own-color2 item 2 beliefs
                  let other-colors2 item 3 beliefs
                  let dirt-left2 item 4 beliefs
                  let other-locations2 item 5 beliefs

                  set other-colors2 remove own-color other-colors2

                  set beliefs []
                  set beliefs lput color-choice2 beliefs
                  set beliefs lput dirty-locations2 beliefs
                  set beliefs lput own-color2 beliefs
                  set beliefs lput other-colors2 beliefs
                  set beliefs lput dirt-left2 beliefs
                  set beliefs lput other-locations2 beliefs
                ]
              ]
            ]
            if (not found) [
              set intention "move"
            ]
          ]
        ] [
         set intention "stop"
        ]
      ]
   ]

   set beliefs []
   set beliefs lput color-choice beliefs
   set beliefs lput dirty-locations beliefs
   set beliefs lput own-color beliefs
   set beliefs lput other-colors beliefs
   set beliefs lput dirt-left beliefs
   set beliefs lput other-locations beliefs
  ]
end


; --- Execute actions ---
to execute-actions
  ; Here you should put the code related to the actions performed by your agent: moving, cleaning, and (actively) looking around.
  ; Please note that your agents should perform only one action per tick!
  ask vacuums [
    let color-choice item 0 beliefs
    let dirty-locations item 1 beliefs
    let own-color item 2 beliefs
    let other-colors item 3 beliefs
    let dirt-left item 4 beliefs
    let other-locations item 5 beliefs

    ifelse (intention = "look-around") [
      ask patches in-radius vision_radius [
       ifelse (pcolor = [color] of myself) [
         let co []
         set co lput pxcor co
         set co lput pycor co
         if (not in dirty-locations co) [
           set dirty-locations lput co dirty-locations
         ]
       ] [
         if (pcolor != white) [
           let co []
           set co lput pxcor co
           set co lput pycor co
           set co lput pcolor co

           let not-in-it true
           foreach other-locations [
             if (item 0 ? = item 0 co and item 1 ? = item 1 co and item 2 ? = item 2 co) [
               set not-in-it false
             ]
           ]

           if (not-in-it) [
             set co lput false co
             set other-locations lput co other-locations

             let new-color-choice []
             foreach color-choice [
               let c item 0 ?
               let i item 1 ?
               if (c = item 2 co) [
                 set i i + 1
               ]
               let q []
               set q lput c q
               set q lput i q
               set new-color-choice lput q new-color-choice
             ]
             set color-choice new-color-choice
           ]
         ]
       ]
     ]
   ] [
      ifelse (intention = "choose") [
        set color own-color
        set dirt-left count patches with [pcolor = own-color]

        foreach other-locations [
          let x item 0 ?
          let y item 1 ?
          let c item 2 ?
          if (c = own-color) [
            let l []
            set l lput x l
            set l lput y l
            set dirty-locations lput l dirty-locations
            set other-locations remove ? other-locations
          ]
        ]
      ] [
        ifelse (intention = "stop")
        [
          set heading heading + 5
        ] [
          ifelse (intention = "move")
          [
            ifelse random 100 < 20
            [
              set heading random 360
            ]
            [
              fd 1
            ]
          ]
          [
            let l item 0 dirty-locations
            let x item 0 l
            let y item 1 l
            if (intention = "turnto")
            [
              facexy x y
            ]
            if (intention = "moveto")
            [
              ifelse (distancexy x y < 1)
              [
                setxy x y
              ]
              [
                fd 1
              ]
            ]
            if (intention = "clean")
            [
              if ([pcolor] of patch x y = own-color) [
                ; because of small bug in tick-updates, need to check this again
                set dirt-left dirt-left - 1
              ]
              ask patch x y [
                set pcolor white
              ]
              set dirty-locations but-first dirty-locations
            ]
          ]
        ]
      ]
    ]
    set beliefs []
    set beliefs lput color-choice beliefs
    set beliefs lput dirty-locations beliefs
    set beliefs lput own-color beliefs
    set beliefs lput other-colors beliefs
    set beliefs lput dirt-left beliefs
    set beliefs lput other-locations beliefs


    ask link-neighbors
    [
      setxy [xcor] of myself [ycor] of myself
      let c [color] of myself
      set color lput 90 extract-rgb c
    ]
  ]
end


; --- Send messages ---
to send-messages
  ; Here should put the code related to sending messages to other agents.
  ; Note that this could be seen as a special case of executing actions, but for conceptual clarity it has been put in a separate method.
  ask vacuums [
   set outgoing_messages []
   set incoming_messages []
  ]
  ask vacuums [
    let own-color item 2 beliefs
    let other-colors item 3 beliefs
    let other-locations item 5 beliefs
    let new-other-locations []
    foreach other-locations [
      let x item 0 ?
      let y item 1 ?
      let c item 2 ?
      let m item 3 ?
      ifelse (in other-colors c or m) [
        set new-other-locations lput ? new-other-locations
      ] [
        let q []
        set q lput x q
        set q lput y q
        set q lput c q
        set outgoing_messages lput q outgoing_messages
        set q lput true q
        set new-other-locations lput q new-other-locations
      ]
    ]
    set beliefs but-last beliefs
    set beliefs lput new-other-locations beliefs
    foreach outgoing_messages [
      let co but-last ?
      let c last ?
      ask vacuums [
        if ([color] of self = c) [
          set incoming_messages lput co incoming_messages
        ]
      ]
    ]
    if (intention = "choose") [
      let q []
      set q lput "color-set" q
      set q lput own-color q
      set outgoing_messages lput q outgoing_messages
      ask vacuums [
        set incoming_messages lput q incoming_messages
      ]
    ]
  ]
end

to-report in [l i]
  let ans false
  foreach l [
    if (? = i) [
      set ans true
    ]
  ]
  report ans
end
@#$#@#$#@
GRAPHICS-WINDOW
786
46
1303
584
12
12
20.31
1
10
1
1
1
0
0
0
1
-12
12
-12
12
1
1
1
ticks
30.0

SLIDER
6
133
772
166
dirt_pct
dirt_pct
0
100
27
1
1
NIL
HORIZONTAL

BUTTON
6
101
390
134
NIL
go
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

BUTTON
389
101
772
134
NIL
go
T
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

BUTTON
6
243
772
276
NIL
setup
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

SLIDER
6
169
772
202
num_agents
num_agents
2
7
7
1
1
NIL
HORIZONTAL

SLIDER
5
206
772
239
vision_radius
vision_radius
0
100
4
1
1
NIL
HORIZONTAL

MONITOR
457
276
773
321
Intention of vacuum 1
[intention] of vacuum 0
17
1
11

MONITOR
114
276
459
321
Desire of vacuum 1
[desire] of vacuum 0
17
1
11

MONITOR
6
320
774
365
Beliefs of vacuum 1
[beliefs] of vacuum 0
17
1
11

MONITOR
5
465
772
510
Beliefs of vacuum 2
[beliefs] of vacuum 1
17
1
11

MONITOR
6
276
115
321
Color of vacuum 1
item 2 [beliefs] of vacuum 0
17
1
11

MONITOR
5
421
115
466
Color of vacuum 2
item 2 [beliefs] of vacuum 1
17
1
11

MONITOR
452
421
772
466
Intention of vacuum 2
[intention] of vacuum 1
17
1
11

MONITOR
115
421
452
466
Desire of vacuum 2
[desire] of vacuum 1
17
1
11

MONITOR
5
566
113
611
Color of vacuum 3
item 2 [beliefs] of vacuum 2
17
1
11

MONITOR
5
610
772
655
Beliefs of vacuum 3
[beliefs] of vacuum 2
17
1
11

MONITOR
453
566
772
611
Intention of vacuum 3
[intention] of vacuum 2
17
1
11

MONITOR
113
566
453
611
Desire of vacuum 3
[desire] of vacuum 2
17
1
11

MONITOR
6
364
385
409
Outgoing messages vacuum 1
sort ([outgoing_messages] of vacuum 0)
17
1
11

MONITOR
385
364
774
409
Incoming messages vacuum 1
[incoming_messages] of vacuum 0
17
1
11

MONITOR
5
508
389
553
Outgoing messages vacuum 2
sort ([outgoing_messages] of vacuum 1)
17
1
11

MONITOR
388
508
772
553
Incoming messages vacuum 2
[incoming_messages] of vacuum 1
17
1
11

MONITOR
6
653
389
698
Outgoing messages vacuum 3
sort ([outgoing_messages] of vacuum 2)
17
1
11

MONITOR
389
653
772
698
Incoming messages vacuum 3
[incoming_messages] of vacuum 2
17
1
11

MONITOR
7
47
771
92
Time to complete the task.
time
17
1
11

SLIDER
7
10
770
43
color-thresh
color-thresh
0
100
9
1
1
NIL
HORIZONTAL

@#$#@#$#@
## WHAT IS IT?

(a general understanding of what the model is trying to show or explain)

## HOW IT WORKS

(what rules the agents use to create the overall behavior of the model)

## HOW TO USE IT

(how to use the model, including a description of each of the items in the Interface tab)

## THINGS TO NOTICE

(suggested things for the user to notice while running the model)

## THINGS TO TRY

(suggested things for the user to try to do (move sliders, switches, etc.) with the model)

## EXTENDING THE MODEL

(suggested things to add or change in the Code tab to make the model more complicated, detailed, accurate, etc.)

## NETLOGO FEATURES

(interesting or unusual features of NetLogo that the model uses, particularly in the Code tab; or where workarounds were needed for missing features)

## RELATED MODELS

(models in the NetLogo Models Library and elsewhere which are of related interest)

## CREDITS AND REFERENCES

(a reference to the model's URL on the web if it has one, as well as any other necessary credits, citations, and links)
@#$#@#$#@
default
true
0
Polygon -7500403 true true 150 5 40 250 150 205 260 250

airplane
true
0
Polygon -7500403 true true 150 0 135 15 120 60 120 105 15 165 15 195 120 180 135 240 105 270 120 285 150 270 180 285 210 270 165 240 180 180 285 195 285 165 180 105 180 60 165 15

arrow
true
0
Polygon -7500403 true true 150 0 0 150 105 150 105 293 195 293 195 150 300 150

box
false
0
Polygon -7500403 true true 150 285 285 225 285 75 150 135
Polygon -7500403 true true 150 135 15 75 150 15 285 75
Polygon -7500403 true true 15 75 15 225 150 285 150 135
Line -16777216 false 150 285 150 135
Line -16777216 false 150 135 15 75
Line -16777216 false 150 135 285 75

bug
true
0
Circle -7500403 true true 96 182 108
Circle -7500403 true true 110 127 80
Circle -7500403 true true 110 75 80
Line -7500403 true 150 100 80 30
Line -7500403 true 150 100 220 30

butterfly
true
0
Polygon -7500403 true true 150 165 209 199 225 225 225 255 195 270 165 255 150 240
Polygon -7500403 true true 150 165 89 198 75 225 75 255 105 270 135 255 150 240
Polygon -7500403 true true 139 148 100 105 55 90 25 90 10 105 10 135 25 180 40 195 85 194 139 163
Polygon -7500403 true true 162 150 200 105 245 90 275 90 290 105 290 135 275 180 260 195 215 195 162 165
Polygon -16777216 true false 150 255 135 225 120 150 135 120 150 105 165 120 180 150 165 225
Circle -16777216 true false 135 90 30
Line -16777216 false 150 105 195 60
Line -16777216 false 150 105 105 60

car
false
0
Polygon -7500403 true true 300 180 279 164 261 144 240 135 226 132 213 106 203 84 185 63 159 50 135 50 75 60 0 150 0 165 0 225 300 225 300 180
Circle -16777216 true false 180 180 90
Circle -16777216 true false 30 180 90
Polygon -16777216 true false 162 80 132 78 134 135 209 135 194 105 189 96 180 89
Circle -7500403 true true 47 195 58
Circle -7500403 true true 195 195 58

circle
false
0
Circle -7500403 true true 0 0 300

circle 2
false
0
Circle -7500403 true true 0 0 300
Circle -16777216 true false 30 30 240

cow
false
0
Polygon -7500403 true true 200 193 197 249 179 249 177 196 166 187 140 189 93 191 78 179 72 211 49 209 48 181 37 149 25 120 25 89 45 72 103 84 179 75 198 76 252 64 272 81 293 103 285 121 255 121 242 118 224 167
Polygon -7500403 true true 73 210 86 251 62 249 48 208
Polygon -7500403 true true 25 114 16 195 9 204 23 213 25 200 39 123

cylinder
false
0
Circle -7500403 true true 0 0 300

dot
false
0
Circle -7500403 true true 90 90 120

face happy
false
0
Circle -7500403 true true 8 8 285
Circle -16777216 true false 60 75 60
Circle -16777216 true false 180 75 60
Polygon -16777216 true false 150 255 90 239 62 213 47 191 67 179 90 203 109 218 150 225 192 218 210 203 227 181 251 194 236 217 212 240

face neutral
false
0
Circle -7500403 true true 8 7 285
Circle -16777216 true false 60 75 60
Circle -16777216 true false 180 75 60
Rectangle -16777216 true false 60 195 240 225

face sad
false
0
Circle -7500403 true true 8 8 285
Circle -16777216 true false 60 75 60
Circle -16777216 true false 180 75 60
Polygon -16777216 true false 150 168 90 184 62 210 47 232 67 244 90 220 109 205 150 198 192 205 210 220 227 242 251 229 236 206 212 183

fish
false
0
Polygon -1 true false 44 131 21 87 15 86 0 120 15 150 0 180 13 214 20 212 45 166
Polygon -1 true false 135 195 119 235 95 218 76 210 46 204 60 165
Polygon -1 true false 75 45 83 77 71 103 86 114 166 78 135 60
Polygon -7500403 true true 30 136 151 77 226 81 280 119 292 146 292 160 287 170 270 195 195 210 151 212 30 166
Circle -16777216 true false 215 106 30

flag
false
0
Rectangle -7500403 true true 60 15 75 300
Polygon -7500403 true true 90 150 270 90 90 30
Line -7500403 true 75 135 90 135
Line -7500403 true 75 45 90 45

flower
false
0
Polygon -10899396 true false 135 120 165 165 180 210 180 240 150 300 165 300 195 240 195 195 165 135
Circle -7500403 true true 85 132 38
Circle -7500403 true true 130 147 38
Circle -7500403 true true 192 85 38
Circle -7500403 true true 85 40 38
Circle -7500403 true true 177 40 38
Circle -7500403 true true 177 132 38
Circle -7500403 true true 70 85 38
Circle -7500403 true true 130 25 38
Circle -7500403 true true 96 51 108
Circle -16777216 true false 113 68 74
Polygon -10899396 true false 189 233 219 188 249 173 279 188 234 218
Polygon -10899396 true false 180 255 150 210 105 210 75 240 135 240

house
false
0
Rectangle -7500403 true true 45 120 255 285
Rectangle -16777216 true false 120 210 180 285
Polygon -7500403 true true 15 120 150 15 285 120
Line -16777216 false 30 120 270 120

leaf
false
0
Polygon -7500403 true true 150 210 135 195 120 210 60 210 30 195 60 180 60 165 15 135 30 120 15 105 40 104 45 90 60 90 90 105 105 120 120 120 105 60 120 60 135 30 150 15 165 30 180 60 195 60 180 120 195 120 210 105 240 90 255 90 263 104 285 105 270 120 285 135 240 165 240 180 270 195 240 210 180 210 165 195
Polygon -7500403 true true 135 195 135 240 120 255 105 255 105 285 135 285 165 240 165 195

line
true
0
Line -7500403 true 150 0 150 300

line half
true
0
Line -7500403 true 150 0 150 150

pentagon
false
0
Polygon -7500403 true true 150 15 15 120 60 285 240 285 285 120

person
false
0
Circle -7500403 true true 110 5 80
Polygon -7500403 true true 105 90 120 195 90 285 105 300 135 300 150 225 165 300 195 300 210 285 180 195 195 90
Rectangle -7500403 true true 127 79 172 94
Polygon -7500403 true true 195 90 240 150 225 180 165 105
Polygon -7500403 true true 105 90 60 150 75 180 135 105

plant
false
0
Rectangle -7500403 true true 135 90 165 300
Polygon -7500403 true true 135 255 90 210 45 195 75 255 135 285
Polygon -7500403 true true 165 255 210 210 255 195 225 255 165 285
Polygon -7500403 true true 135 180 90 135 45 120 75 180 135 210
Polygon -7500403 true true 165 180 165 210 225 180 255 120 210 135
Polygon -7500403 true true 135 105 90 60 45 45 75 105 135 135
Polygon -7500403 true true 165 105 165 135 225 105 255 45 210 60
Polygon -7500403 true true 135 90 120 45 150 15 180 45 165 90

sheep
false
15
Circle -1 true true 203 65 88
Circle -1 true true 70 65 162
Circle -1 true true 150 105 120
Polygon -7500403 true false 218 120 240 165 255 165 278 120
Circle -7500403 true false 214 72 67
Rectangle -1 true true 164 223 179 298
Polygon -1 true true 45 285 30 285 30 240 15 195 45 210
Circle -1 true true 3 83 150
Rectangle -1 true true 65 221 80 296
Polygon -1 true true 195 285 210 285 210 240 240 210 195 210
Polygon -7500403 true false 276 85 285 105 302 99 294 83
Polygon -7500403 true false 219 85 210 105 193 99 201 83

square
false
0
Rectangle -7500403 true true 30 30 270 270

square 2
false
0
Rectangle -7500403 true true 30 30 270 270
Rectangle -16777216 true false 60 60 240 240

star
false
0
Polygon -7500403 true true 151 1 185 108 298 108 207 175 242 282 151 216 59 282 94 175 3 108 116 108

target
false
0
Circle -7500403 true true 0 0 300
Circle -16777216 true false 30 30 240
Circle -7500403 true true 60 60 180
Circle -16777216 true false 90 90 120
Circle -7500403 true true 120 120 60

tree
false
0
Circle -7500403 true true 118 3 94
Rectangle -6459832 true false 120 195 180 300
Circle -7500403 true true 65 21 108
Circle -7500403 true true 116 41 127
Circle -7500403 true true 45 90 120
Circle -7500403 true true 104 74 152

triangle
false
0
Polygon -7500403 true true 150 30 15 255 285 255

triangle 2
false
0
Polygon -7500403 true true 150 30 15 255 285 255
Polygon -16777216 true false 151 99 225 223 75 224

truck
false
0
Rectangle -7500403 true true 4 45 195 187
Polygon -7500403 true true 296 193 296 150 259 134 244 104 208 104 207 194
Rectangle -1 true false 195 60 195 105
Polygon -16777216 true false 238 112 252 141 219 141 218 112
Circle -16777216 true false 234 174 42
Rectangle -7500403 true true 181 185 214 194
Circle -16777216 true false 144 174 42
Circle -16777216 true false 24 174 42
Circle -7500403 false true 24 174 42
Circle -7500403 false true 144 174 42
Circle -7500403 false true 234 174 42

turtle
true
0
Polygon -10899396 true false 215 204 240 233 246 254 228 266 215 252 193 210
Polygon -10899396 true false 195 90 225 75 245 75 260 89 269 108 261 124 240 105 225 105 210 105
Polygon -10899396 true false 105 90 75 75 55 75 40 89 31 108 39 124 60 105 75 105 90 105
Polygon -10899396 true false 132 85 134 64 107 51 108 17 150 2 192 18 192 52 169 65 172 87
Polygon -10899396 true false 85 204 60 233 54 254 72 266 85 252 107 210
Polygon -7500403 true true 119 75 179 75 209 101 224 135 220 225 175 261 128 261 81 224 74 135 88 99

ufo top
false
0
Circle -1 true false 15 15 270
Circle -16777216 false false 15 15 270
Circle -7500403 true true 75 75 150
Circle -16777216 false false 75 75 150
Circle -7500403 true true 60 60 30
Circle -7500403 true true 135 30 30
Circle -7500403 true true 210 60 30
Circle -7500403 true true 240 135 30
Circle -7500403 true true 210 210 30
Circle -7500403 true true 135 240 30
Circle -7500403 true true 60 210 30
Circle -7500403 true true 30 135 30
Circle -16777216 false false 30 135 30
Circle -16777216 false false 60 210 30
Circle -16777216 false false 135 240 30
Circle -16777216 false false 210 210 30
Circle -16777216 false false 240 135 30
Circle -16777216 false false 210 60 30
Circle -16777216 false false 135 30 30
Circle -16777216 false false 60 60 30

vacuum-cleaner
true
0
Polygon -2674135 true false 75 90 105 150 165 150 135 135 105 135 90 90 75 90
Circle -2674135 true false 105 135 30
Rectangle -2674135 true false 75 105 90 120

wheel
false
0
Circle -7500403 true true 3 3 294
Circle -16777216 true false 30 30 240
Line -7500403 true 150 285 150 15
Line -7500403 true 15 150 285 150
Circle -7500403 true true 120 120 60
Line -7500403 true 216 40 79 269
Line -7500403 true 40 84 269 221
Line -7500403 true 40 216 269 79
Line -7500403 true 84 40 221 269

wolf
false
0
Polygon -16777216 true false 253 133 245 131 245 133
Polygon -7500403 true true 2 194 13 197 30 191 38 193 38 205 20 226 20 257 27 265 38 266 40 260 31 253 31 230 60 206 68 198 75 209 66 228 65 243 82 261 84 268 100 267 103 261 77 239 79 231 100 207 98 196 119 201 143 202 160 195 166 210 172 213 173 238 167 251 160 248 154 265 169 264 178 247 186 240 198 260 200 271 217 271 219 262 207 258 195 230 192 198 210 184 227 164 242 144 259 145 284 151 277 141 293 140 299 134 297 127 273 119 270 105
Polygon -7500403 true true -1 195 14 180 36 166 40 153 53 140 82 131 134 133 159 126 188 115 227 108 236 102 238 98 268 86 269 92 281 87 269 103 269 113

x
false
0
Polygon -7500403 true true 270 75 225 30 30 225 75 270
Polygon -7500403 true true 30 75 75 30 270 225 225 270

@#$#@#$#@
NetLogo 5.3
@#$#@#$#@
@#$#@#$#@
@#$#@#$#@
@#$#@#$#@
@#$#@#$#@
default
0.0
-0.2 0 0.0 1.0
0.0 1 1.0 0.0
0.2 0 0.0 1.0
link direction
true
0
Line -7500403 true 150 150 90 180
Line -7500403 true 150 150 210 180

shape-sensor
0.0
-0.2 0 0.0 1.0
0.0 1 1.0 0.0
0.2 0 0.0 1.0
link direction
true
0

@#$#@#$#@
0
@#$#@#$#@
