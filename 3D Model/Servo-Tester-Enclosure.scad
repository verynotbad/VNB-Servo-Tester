use <MCAD/shapes.scad>
include <arduino.scad>

$fn = 30;

wallHeight = 36;

// ----------------------------------------------
// -- Visibility
// ----------------------------------------------

SHOW_ELECTRONICS			= false;

SHOW_TOP 					= false;
SHOW_BOTTOM 				= false;
SHOW_PUSHBUTTONS			= true;

SHOW_CRADLE					= false;

// ----------------------------------------------
// -- Base Parameters
// ----------------------------------------------
wallThickness		= 2.0;
baseThickness		= 3.0;

bottomHeight		= 18.0;

enclosureGapX		= 10.0;
enclosureGapY		= 1.0;

fastenerHoleD		= 3.3;
fastenerSupportX	= 9.0;
fastenerSupportY	= 10.0;

pushButtonH			= 10.0;
pushButtonZ			= 37.5;

bumperOffsetZ		= -2.1;
boardMountingHoleZ	= abs(bumperOffsetZ) + baseThickness + 2;


unoSize = boardDimensions(UNO);
electronicsLengthY = 81.3;
enclosureSizeX = unoSize[0] + (enclosureGapX + wallThickness)*2;
enclosureSizeY = electronicsLengthY + (enclosureGapY + wallThickness)*2;
//enclosureSize = [enclosureSizeX, enclosureSizeY, 0];

offsetX = (wallThickness + enclosureGapX) * -1;
offsetY = (wallThickness + enclosureGapY) * -1;

servoConnectorOpening = [15, 10, 6.1];


echo("Enclosure Size:");
echo("X: ", enclosureSizeX);
echo("Y: ", enclosureSizeY);


// ------------------------------------------------------------
// -- Model Root
// ------------------------------------------------------------

unoSize = boardDimensions(UNO);

	union()
	{

		if (SHOW_ELECTRONICS)
		{
			electronics();
		}

		difference()
		{
			union()
			{
				if (SHOW_TOP)
				{
					translate([0,0,0.1])
					enclosureTop(electronicsLengthY=81.3, topHeight=27, bottomHeight=bottomHeight);
				}

				if (SHOW_BOTTOM)
				{
					translate([0,0,0])
					enclosureBottom(electronicsLengthY=81.3, height=bottomHeight);
				}

				if (SHOW_CRADLE)
				{
					translate([0,0,0])
					enclosureCradle();
				}
			}
			
			
			//enclosureOpenings(height=bottomHeight);



			//arduinoMountingHoles();
			//enclosureOpenings();
			
		}
	}




	
if (SHOW_PUSHBUTTONS)
{
	color("Orange")
	translate([0, 0, pushButtonZ])
	lcdShield(pcb=false, display=false, buttons=false, btnHoleD=4.0, btnHoles=false, resetHole=false, screenHole=false, pushButtons=true, pushButtonH=pushButtonH);
}








// -----------------------------------------------------------------
// -- Modules
// -----------------------------------------------------------------

module enclosureTop(electronicsLengthY, topHeight=15, bottomHeight=10)
{

	enclosureSize = [enclosureSizeX, enclosureSizeY, topHeight];
	cutoutSize    = [enclosureSizeX-(wallThickness*2), enclosureSizeY-(wallThickness*2), topHeight];

	offsetX = (wallThickness + enclosureGapX) * -1;
	offsetY = (wallThickness + enclosureGapY) * -1;
	offsetZ = bottomHeight - baseThickness + bumperOffsetZ;


	difference()
	{
		union()
		{
			difference()
			{
				// -- Outer Walls
				translate([offsetX, offsetY, offsetZ])
				cube(enclosureSize);

				// -- Center Cutout
				translate([offsetX + wallThickness, offsetY + wallThickness, offsetZ - baseThickness])
				cube(cutoutSize);

			}

				// -- Top/Bottom Fastener Support Columns
				fastenerColumns(height=topHeight, offsetZ=offsetZ);
		}

		components( boardType = UNO, component = USB, extension = 5, offset = 0.5);
		components( boardType = UNO, component = POWER, extension = 5, offset = 0.5);

		translate([0, 0, offsetZ])
		lcdShield(pcb=false, display=false, buttons=false, btnHoleD=4.0, btnHoles=true, resetHole=false, screenHole=true);

		fastenerHoles(height=topHeight-2, offsetZ=offsetZ-1, d=3.0);
	}






}


module enclosureBottom(electronicsLengthY, height=10)
{
				translate([0,0,bumperOffsetZ])
				bumper(UNO);
	
/*
	unoSize = boardDimensions(UNO);

	enclosureSizeX = unoSize[0] + (enclosureGapX + wallThickness)*2;
	enclosureSizeY = electronicsLengthY + (enclosureGapY + wallThickness)*2;
*/

	enclosureSize = [enclosureSizeX, enclosureSizeY, height];
	cutoutSize    = [enclosureSizeX-(wallThickness*2), enclosureSizeY-(wallThickness*2), height];

	offsetX = (wallThickness + enclosureGapX) * -1;
	offsetY = (wallThickness + enclosureGapY) * -1;
	offsetZ = -1 * baseThickness + bumperOffsetZ;

	difference()
	{
		union()
		{
			difference()
			{		
				// -- Outer Walls
				translate([offsetX, offsetY, offsetZ])
				cube(enclosureSize);

				// -- Center Cutout
				translate([offsetX + wallThickness, offsetY + wallThickness, offsetZ + baseThickness])
				cube(cutoutSize);


			}

			// -- Top/Bottom Fastener Support Columns
			fastenerColumns(height=height, offsetZ=offsetZ);

		}

		components( boardType = UNO, component = USB, extension = 5, offset = 0.5);
		components( boardType = UNO, component = POWER, extension = 5, offset = 0.5);

		// -- Hole for Servo Connectors
		translate([unoSize[0]/2-5, 81.0, height+offsetZ-servoConnectorOpening[2] + 0.1])
		cube(servoConnectorOpening);


		fastenerHoles(height=height+2, offsetZ=offsetZ-1, d=3.0);

		// -- Arduino Mounting Holes
			for(i = boardHoles[UNO] ) 
			{
    			translate([i[0], i[1], boardMountingHoleZ*-1])
    			cylinder(d=3.3, h=boardMountingHoleZ);
  			}

	}


	
}


module enclosureCradle()
{
	enclosureSize = [enclosureSizeX, enclosureSizeY, 100];

	offsetX = (wallThickness + enclosureGapX) * -1;
	offsetY = (wallThickness + enclosureGapY) * -1;
	offsetZ = -1 * baseThickness + bumperOffsetZ;

	cradleHeight    = 60.0;
	baseHeight	 	= 30;
	wallThickness 	= 5.0;
	cutoutDepth 	= baseHeight-20.0;
	cutoutGap		= 0.75;
	sideCutoutX		= enclosureSizeX-20;
	sideCutoutOffset= 10;

	cutoutDepthAdder = 15;

	rotate([0,35,0])
	difference() 
	{
		union()
		{ 
			// -- Cradle
			color("Red")
			translate([offsetX-wallThickness, offsetY-wallThickness, offsetZ-cutoutDepth])
			rotate([0,0,0])
			cube([enclosureSize[0]+(wallThickness*2), enclosureSize[1]+(wallThickness*2), baseHeight-cutoutDepthAdder], center=false);

			rotate([0,-35,0])
			intersection() 
			{
			
				color("Red")
				translate([offsetX - enclosureSize[0], offsetY-wallThickness, cradleHeight*-1+3])
				rotate([0,0,0])
				cube([enclosureSize[0]*2, enclosureSize[1]+(wallThickness*2), cradleHeight], center=false);

				color("Red")
				rotate([0,35,0])
				translate([offsetX-wallThickness, offsetY-wallThickness, offsetZ-cutoutDepth-100])
				cube([enclosureSize[0]+(wallThickness*2), enclosureSize[1]+(wallThickness*2), 110], center=false);

				translate([-27.5,-50,-80])
				cube([100,200,100]);

			}


		}

		color("Orange")
		translate([offsetX-cutoutGap, offsetY-cutoutGap, offsetZ-cutoutDepthAdder])
		rotate([0,0,0])
		cube([enclosureSize[0]+(cutoutGap*2), enclosureSize[1]+(cutoutGap*2), 100], center=false);

		// -- Side Cutouts for Wires
		color("Orange")
		translate([offsetX-cutoutGap + sideCutoutOffset, offsetY-cutoutGap-enclosureSize[1]/2, offsetZ-cutoutDepthAdder])
		rotate([0,0,0])
		cube([sideCutoutX, enclosureSize[1]*2+(cutoutGap*2), 100], center=false);



	}


}


module fastenerColumns(height, offsetZ)
{
	offsetX = (wallThickness + enclosureGapX) * -1;
	offsetY = (wallThickness + enclosureGapY) * -1;
	//offsetZ = -1 * baseThickness + bumperOffsetZ;

	supportXL = enclosureGapX*-1;
	supportXR = enclosureSizeX + offsetX - fastenerSupportX - wallThickness;
	supportYB = enclosureGapY*-1;
	supportYT = enclosureSizeY + offsetY - fastenerSupportY - wallThickness;

	// -- Top/Bottom Fastener Support Columns
	translate([supportXL, supportYB, offsetZ])
	cube([fastenerSupportX, fastenerSupportY, height]);

	translate([supportXL,supportYT, offsetZ])
	cube([fastenerSupportX, fastenerSupportY, height]);

	translate([supportXR, supportYB, offsetZ])
	cube([fastenerSupportX, fastenerSupportY, height]);

	translate([supportXR,supportYT, offsetZ])
	cube([fastenerSupportX, fastenerSupportY, height]);

}

module fastenerHoles(height, offsetZ=0, d=3.0)
{
	offsetX = (wallThickness + enclosureGapX) * -1;
	offsetY = (wallThickness + enclosureGapY) * -1;
	//offsetZ = -1 * baseThickness + bumperOffsetZ;

	supportXL = enclosureGapX*-1 + fastenerSupportX/2;
	supportXR = enclosureSizeX + offsetX - fastenerSupportX - wallThickness + fastenerSupportX/2;
	supportYB = enclosureGapY*-1 + fastenerSupportY/2;
	supportYT = enclosureSizeY + offsetY - fastenerSupportY - wallThickness + fastenerSupportY/2;


	translate([supportXL, supportYB, offsetZ])
	cylinder(d=d, h=height);

	translate([supportXL, supportYT, offsetZ])
	cylinder(d=d, h=height);

	translate([supportXR, supportYB, offsetZ])
	cylinder(d=d, h=height);

	translate([supportXR, supportYT, offsetZ])
	cylinder(d=d, h=height);

}


module electronics()
{
	// -- Arduino Board
	translate([0,0,0])
	arduino(UNO);

	// -- Prototype Shield
	translate([0,0,13.0])
	union()
	{
		color("SteelBlue")
		boardShape(UNO);

		components( boardType = UNO, component = HEADER_F );
	}

	// -- LCD Shield
	translate([0, 0, 25.3])
	lcdShield();
}


module lcdShield(pcb=true, display=true, buttons=true, btnHoleD=4.0, btnHoles=false, resetHole=false, screenHole=false, screenHoleGap=0.5, pushButtons=false, pushButtonH=5.0)
{
	btnLeft 		= [46.6, 4.6, 0];
	btnRight		= [46.6, 19.9, 0];
	btnUp			= [43.3, 12.1, 0];
	btnDown			= [50.3, 12.1, 0];
	btnSelect		= [43.3, 28.4, 0];
	btnReset		= [50.3, 78, 0];

	pushButtonBaseH	= 3.0;
	pushButtonBaseD	= 5.0;
	pushButtonDGap	= 0.75;

	screenSize		= [26.5, 71.5, 10];
	screenOffset 	= [7.5, 5.0, 6.0];

	screenHoleSize	= [screenSize[0]+screenHoleGap*2, screenSize[1]+screenHoleGap*2, screenSize[2]+screenHoleGap*2+100];
	screenHoleOffset= [screenOffset[0] - screenHoleGap, screenOffset[1] - screenHoleGap, screenOffset[2] - screenHoleGap - 50];

	if (pcb)
	{
		// -- PCB (Lower)
		color("SteelBlue")
 		cube([53.4, 81.30, 1.7]);	

		// -- PCB (Upper)
		translate([3.0,0,4.3])
		color("SteelBlue")
 		cube([36.0, 81.30, 1.7]);	
 }

 	// -- LCD Screen
 	if (display)
 	{
 		translate(screenOffset)
 		color("black")
 		cube(screenSize);
 	}

 	if (screenHole)
 	{
  		translate(screenHoleOffset)
 		cube(screenHoleSize);
 		
 	}


 	// -- Buttons
 	if (buttons)
 	{
	 	// -- LEFT
	 	translate(btnLeft)
	 	smallTactileButton();

	 	// -- RIGHT
	  	translate(btnRight)
	 	smallTactileButton();

	 	// -- UP
	  	translate(btnUp)
	 	smallTactileButton();

	 	// -- DOWN
	  	translate(btnDown)
	 	smallTactileButton();

	 	// -- SELECT
	  	translate(btnSelect)
	 	smallTactileButton();

	 	// -- RESET
	  	translate(btnReset)
	 	smallTactileButton();
 	}


 	if (btnHoles)
 	{
	 	// -- LEFT
	 	translate(btnLeft)
	 	cylinder(d=btnHoleD, h=100, center=true);

	 	// -- RIGHT
	  	translate(btnRight)
	 	cylinder(d=btnHoleD, h=100, center=true);

	 	// -- UP
	  	translate(btnUp)
	 	cylinder(d=btnHoleD, h=100, center=true);

	 	// -- DOWN
	  	translate(btnDown)
	 	cylinder(d=btnHoleD, h=100, center=true);

	 	// -- SELECT
	  	translate(btnSelect)
	 	cylinder(d=btnHoleD, h=100, center=true);
	}

 	if (resetHole)
 	{
	 	// -- UP
	  	translate(btnReset)
	 	cylinder(d=btnHoleD, h=100, center=true);


 	}


 	if (pushButtons)
 	{
	 	// -- LEFT
	 	translate(btnLeft)
	 	{
	 		cylinder(d=btnHoleD-pushButtonDGap, h=pushButtonH, center=true);

	 		translate([0,0,(pushButtonH-pushButtonBaseH)/-2])
	 		cylinder(d=pushButtonBaseD, h=pushButtonBaseH, center=true);
		}

	 	// -- RIGHT
	  	translate(btnRight)
	 	{
	 		cylinder(d=btnHoleD-pushButtonDGap, h=pushButtonH, center=true);

	 		translate([0,0,(pushButtonH-pushButtonBaseH)/-2])
	 		cylinder(d=pushButtonBaseD, h=pushButtonBaseH, center=true);
		}

	 	// -- UP
	  	translate(btnUp)
	 	{
	 		cylinder(d=btnHoleD-pushButtonDGap, h=pushButtonH, center=true);

	 		translate([0,0,(pushButtonH-pushButtonBaseH)/-2])
	 		cylinder(d=pushButtonBaseD, h=pushButtonBaseH, center=true);
		}

	 	// -- DOWN
	  	translate(btnDown)
	 	{
	 		cylinder(d=btnHoleD-pushButtonDGap, h=pushButtonH, center=true);

	 		translate([0,0,(pushButtonH-pushButtonBaseH)/-2])
	 		cylinder(d=pushButtonBaseD, h=pushButtonBaseH, center=true);
		}

	 	// -- SELECT
	  	translate(btnSelect)
	 	{
	 		cylinder(d=btnHoleD-pushButtonDGap, h=pushButtonH, center=true);

	 		translate([0,0,(pushButtonH-pushButtonBaseH)/-2])
	 		cylinder(d=pushButtonBaseD, h=pushButtonBaseH, center=true);
		}

 	}

}

module smallTactileButton()
{
	d=4.0;
	h=1.6;

	translate([0,0,5.4 + h/2])
	color("Black") 
	cylinder(d=d, h=h, center=true);


	translate([0,0,1.7 + 1.8])
	color("DarkGray") 
	cube([6, 6, 3.7], center=true);
}









