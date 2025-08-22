group "Twist Joint"
(
    spinner sp_Angle "Angle:" Type:#float Range:[0, 360, 180] scale:0.1
    button bt_Angle1 "1" width:20 across:5 align:#left
    button bt_Angle2 "5" width:20  offset:[-6,0]
    button bt_Angle3 "10" width:25  offset:[-6,0]
    button bt_Angle4 "22.5" width:30 
    button bt_Angle5 "90" width:25 align:#right
    radiobuttons rb_Keys "Modify:" labels:#("All keys", "Current frame") columns:1 align:#left
    button bt_TwistCW "<< CCW" width:65 height:30 across:2 align:#left
    button bt_TwistCCW "CW >>" width:65 height:30 align:#right

    on bt_Angle1 pressed do (
        sp_Angle.value = 1
    )

    on bt_Angle2 pressed do (
        sp_Angle.value = 5
    )

    on bt_Angle3 pressed do (
        sp_Angle.value = 10
    )

    on bt_Angle4 pressed do (
        sp_Angle.value = 22.5
    )

    on bt_Angle5 pressed do (
        sp_Angle.value = 90
    )

    on rb_Keys changed state do (
        print state
    )

    on bt_TwistCW pressed do (
        undo "Twist Joint clockwise" on (
            CAfuncs.twistFKCTRL (-1.0 * sp_Angle.value) rb_Keys.state
        )
    ) 

    on bt_TwistCCW pressed do (
        undo "Twist Joint counter clockwise" on (
            CAfuncs.twistFKCTRL sp_Angle.value rb_Keys.state
        )
    ) 
)