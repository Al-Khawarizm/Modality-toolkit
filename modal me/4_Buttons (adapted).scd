/// Buttons

/*
NOTES:
copied from modality source: "/Users/hQi/Documents/GitHub/ModalityWorkshop/modalities-sonic-expression/4_Buttons.scd"
adapted to my Apophenic code

*/

// Buttons can be used in various ways...

// most buttons have a default state (off), and a state when they are pressed (on).

// k = MKtl( 'lpd80' );
// k.gui;
~winAPC40 = Window("AKAI APC40",
	Rect(
		left: 6,
		top: 6,
		width: (Window.screenBounds.width - 770),
		height: (Window.screenBounds.height - 350)
), resizable: true, border: true, scroll: false)
.front
.alwaysOnTop_(false);
~apc40 = MKtl('AKAI APC40', "akai-apc40-saCustom");
~apc40.gui(~winAPC40);
~apc40.reset; // ensure no current assigned actions

s.boot;

~apc40.reset;

MIDIIn.noteOnZeroAsNoteOff_( false );


// ---------------- on - off --------------

// the simplest version is just on-off

Ndef( \testSynth, { | on=0 | SinOsc.ar( 440, 0, on * 0.5 ) } );
Ndef( \testSynth ).play;

~apc40.elementAt( \bt, \clip, \1, \1, \on).action = { arg el; Ndef( \testSynth ).set( \on, 1 ) }; // works
~apc40.elementAt( \bt, \clip, \1, \1, \off ).action = { arg el;  Ndef( \testSynth ).set( \on, 0 ) }; // works


// --------------- toggle -------------

// next one up is a toggle:
~apc40.reset;

~buttonState = 0;

~apc40.elementAt( \bt, \clip, \1, \1, \on).action = { arg el; ~buttonState = (~buttonState + 1).mod(2); Ndef( \testSynth ).set( \on, ~buttonState ); }; // works

// try with my 'device onoff' problem
~apc40.elementAt( \bt, \10, \2, \onoff, \on).action = { arg el; ~buttonState = (~buttonState + 1).mod(2); Ndef( \testSynth ).set( \on, ~buttonState ); }; //  it turns sound on when pressed, which remains when pressed again, then stops on third press
~apc40.reset;
// this works as a pair, but seems rather inelegant
~apc40.elementAt( \bt, \10, \2, \onoff, \on).action = { arg el; ~buttonState = (~buttonState + 1).mod(2); Ndef( \testSynth ).set( \on, ~buttonState ); };
~apc40.elementAt( \bt, \10, \2, \onoff, \off).action = { arg el; ~buttonState = (~buttonState + 1).mod(2); Ndef( \testSynth ).set( \on, ~buttonState ); };



// ---------------------------------------------------------------------------------------------------- ME
// my work looking at the clip on off problem again
( // works as long is clip is depressed, so does not toggle
~buttonState = 0;
~apc40.elementAt( \bt, \clip, \1, \1, \on).action = { arg el; ~buttonState = (~buttonState + 1).mod(2); Ndef( \testSynth ).set( \on, ~buttonState ); };
~apc40.elementAt( \bt, \clip, \1, \1, \off).action = { arg el; ~buttonState = (~buttonState + 1).mod(2); Ndef( \testSynth ).set( \on, ~buttonState ); };
)
// I encountered same in "/Users/hQi/scwork/sayyazSC/0PROJECTS/sc.SALIMS SALON/hQi.live.SS 3.1/7Ca_GUIB_APCGri"/Users/hQi/scwork/sayyazSC/0PROJECTS/sc.SALIMS SALON/hQi.live.SS 3.1/3_GlobVar02.scd"d.scd"

// this pair works
~togCnt = Array.fill(40, {CountLimit(1)}); // toggle counters for APC40 clipon // put in globVars
~apc40.elementAt( \bt, \clip, \1, \1, \on).action_({ | el |
	if(~togCnt[0].value(el.value == 1),
		{
			"do this".postln;
			Ndef( \testSynth ).set( \on, 1);
		},
		{
			"stop that".postln;
			Ndef( \testSynth ).set( \on, 0);
			~togCnt[0].reset
		}
	);
});
~apc40.elementAt( \bt, \clip, \1, \1, \off).action_({ | el |
	if(~togCnt[1].value(el.value == 1),
		{
			"keep LED on".postln;
			~apc40.elAt(\bt, \clip, \1, \1, \on).do { |el| el.value_(1.0) };
		},
		{
			"now turn LED off".postln;
			~apc40.elAt(\bt, \clip, \1, \1, \on).do { |el| el.value_(0.0) };
			~togCnt[1].reset
		}
	);
});


//// some test synth
Ndef( \testSynth, { | on=0 | SinOsc.ar( 440, 0, on * 0.5 ) } );
Ndef( \testSynth ).play;

~apc40.reset
(
// v001 clip toggle code with LED (momentary) but inelegant
~apc40.elAt(\bt, \clip, \1, \1, \on).action = MFunc.new;
~apc40.elAt(\bt, \clip, \1, \1, \on).action.add( \trace, { |mktel| "% %\n".postf(mktel.name, mktel.value); } );
~clipState = 0;
~apc40.elAt(\bt, \clip, \1, \1, \on).action.add(\toggle, { | el |
	~clipState = (~clipState + 1).mod(2);
	if (~clipState == 1,
		{ // turns clip 1 LED on
			~apc40.elAt(\bt, \clip, \1, \1, \on).do { |elem| elem.value_(1.0) };
			"LED on".postln;
		},
		{  // turns clip 1 LED off
			~apc40.elAt(\bt, \clip, \1, \1, \on).do { |elem| elem.value_(0.0) };
			"LED off".postln;
		}
	);
	// do something
	Ndef( \testSynth ).set( \on, ~clipState );
});
)

~apc40.reset
(
// v002 toggle code for all clip ons with LED
// all clip on elements
~clip =
(~apc40.elAt(\bt, \clip, nil, nil, \on).flat ).do { | clipEl |
	var clipState = 0;
	clipEl.action = MFunc.new;
	clipEl.action.add( \trace, { |mktel| "% %\n".postf(mktel.name, mktel.value); } );
	clipEl.action.add(\toggle, { | el |
		clipState = (clipState + 1).mod(2);
		if (clipState == 1,
			{ clipEl.do { |elem| elem.value_(1.0) }; "LED on".postln; },
			{ clipEl.do { |elem| elem.value_(0.0) }; "LED off".postln; }
		);
		// do something
		Ndef( \testSynth ).set( \on, clipState );
	});
};
)
// to access a clip on, but this is not easily readable as row, then button
~clip[32] // is MKtlElement('bt_clip_4_5_on', 'button')
/*
row 1 clips are 0..7
row 2 clips are 8..15
row 3 clips are 16..23
row 4 clips are 24..31
row 5 clips are 32..39
*/

~apc40.reset
( // not quite!!
// v003 toggle code for all clip ons with LED
// index by track and clip
~clip = ~apc40.elAt(\bt, \clip, nil, nil, \on).flop.do({ | item, i |
	[ "this is track " ++ i, " the clips in this track are " ++ item ].postln;
	item.do({ | clipEl, num |
		var clipState = 0;
		["clip " ++ clipEl, " is at track position " ++ num ].postln;
		clipEl.action = MFunc.new;
		clipEl.action.add( \trace, { |mktel| "% %\n".postf(mktel.name, mktel.value); } );
		clipEl.action.add(\toggle, { | el |
			clipState = (clipState + 1).mod(2);
			if (clipState == 1,
				{ clipEl.do { |elem| elem.value_(1.0) }; "LED on".postln; },
				{ clipEl.do { |elem| elem.value_(0.0) }; "LED off".postln; }
			);
			// do something
			Ndef( \testSynth ).set( \on, clipState );
		});
	});
});
~clip[6][0]; // [track][clip] 7th track clip 1

)

~apc40.reset
(
// v004 toggle code for all clip ons with LED; all ons have same function tho
// index by track and clip
~clip = ~apc40.elAt(\bt, \clip, nil, nil, \on).flop.do({ | item, i |
	[ "this is track " ++ i, " the clips in this track are " ++ item ].postln;
	item.do({ | clipEl, num |
		var clipState = 0;
		["clip " ++ clipEl, " is at track position " ++ num ].postln;
		clipEl.action = MFunc.new;
		clipEl.action.add( \trace, { |mktel| "% %\n".postf(mktel.name, mktel.value); } );
		clipEl.action.add(\toggle, { | el |
			clipState = (clipState + 1).mod(2);
			if (clipState == 1,
				{ clipEl.do { |elem| elem.value_(1.0) }; "LED on".postln; },
				{ clipEl.do { |elem| elem.value_(0.0) }; "LED off".postln; }
			);
			// do something
			Ndef( \testSynth ).set( \on, clipState );
		});
	});
});
~clip[6][0]; // [track][clip] 7th track clip 1
)

// I encountered same in "/Users/hQi/scwork/sayyazSC/0PROJECTS/sc.SALIMS SALON/hQi.live.SS 3.1/7Ca_GUIB_APCGri"/Users/hQi/scwork/sayyazSC/0PROJECTS/sc.SALIMS SALON/hQi.live.SS 3.1/3_GlobVar02.scd"d.scd"

~apc40.reset;
(
// v005 works; sound called + LED toggles for a 'pair' of on/off clips
// for now use this
~togOn = Array.fill(40, {CountLimit(1)}); // toggle counters for APC40 clipon // put in globVars
~togOff = Array.fill(40, {CountLimit(1)}); // toggle counters for APC40 clipoff // put in globVars

~apc40.elementAt( \bt, \clip, \1, \1, \on).action_({ | el |
	if(~togOn[0].value(el.value == 1),
		{
			// toggle action on
			Ndef( \testSynth ).set( \on, 1);
			"do this".postln;
		},
		{
			// toggle action off
			Ndef( \testSynth ).set( \on, 0);
			~togOn[0].reset
				"stop that".postln;
		}
	);
});
~apc40.elementAt( \bt, \clip, \1, \1, \off).action_({ | el |
	if(~togOff[1].value(el.value == 1),
		{ ~apc40.elAt(\bt, \clip, \1, \1, \on).do { |el| el.value_(1.0) }; "LED on".postln; },
		{ ~apc40.elAt(\bt, \clip, \1, \1, \on).do { |el| el.value_(0.0) }; "LED off".postln; ~togOff[1].reset }
	);
});
)
// end

// ---------------------------------------------------------------------------------------------------- BACK TO ADAPTED WORKSHOP code



// clean up:
~apc40.reset;
Ndef( \testSynth ).stop;

// ------------- multistate ----------

// a toggle presents two different states that the button can be in, you can also have more states, advancing to the next state each time you press the button:

Ndef( \testSynth, { | select=0 | Select.ar( select, [ SinOsc.ar( 440, 0, 0.1 ), Saw.ar( 440, 0.1 ), Pulse.ar( 440, 0.5, 0.1 ), WhiteNoise.ar( 0.1 ), PinkNoise.ar(0.1) ] ) } );
Ndef( \testSynth ).play;

~buttonMultiState = 0;
~apc40.elementAt( \bt, \clip, \1, \2, \on).action = { arg el; ~buttonMultiState = (~buttonMultiState + 1).mod(5); Ndef( \testSynth ).set( \select, ~buttonMultiState ); };


// clean up:
~apc40.reset;

Ndef( \testSynth ).stop;


// ----------- tracking multiple clicks ----------

// You can also make actions dependent on multiple clicks on the same button, e.g. different actions for a double-click or triple-click, or use the time between clicks as a control value, or make a difference between a soft click before a hard one, and vice versa (if the button is sensitive to how hard you press it).

// the code below records the time between clicks, and for every click that is within a maximum time of a previous click (0.2), it records the time between the clicks (clickDeltas), the number of clicks, and the velocity of the clicks.

// !! this will likely be handy in hQi.live when I want ti track a performance e.g. time between drum onsets
(
~multiclick = IdentityDictionary.new;
~multiclick.put( \clicks, 0 );
~multiclick.put( \clickDeltas, List.new );
~multiclick.put( \clickTimes, IdentityDictionary.new );
~multiclick.put( \clickVals, IdentityDictionary.new );
~multiclick.put( \clickActions, IdentityDictionary.new );
~multiclick.put( \maxClickDelta, 0.4 );
(
~multiclick.put( \timeOut, Task( {
   var clickcount, action;
   ~multiclick[\maxClickDelta].wait; "timeout".postln;
   // value of multiclick
   clickcount = ~multiclick[\clicks];
   // put an action based on the result of the multiclick here:
	// [clickcount, ~multiclick[\clickVals], ~multiclick[ \clickTimes ], ~multiclick[ \clickDeltas ] ].postln;
	action = ~multiclick[ \clickActions ].at( clickcount );
	if ( action.notNil ){ action.value( ~multiclick[\clickVals], ~multiclick[ \clickDeltas ] ); };
   // reset variables:
   ~multiclick.put( \clicks, 0 );
   ~multiclick.put( \clickTimes, IdentityDictionary.new );
   ~multiclick.put( \clickVals, IdentityDictionary.new );
   ~multiclick.put( \clickDeltas, List.new );
} ) );
);
);

(
~apc40.elementAt( \bt, \clip, \1, \1, \on).action = { arg el;
   var thisTime = Process.elapsedTime;
//   if ( ~multiclick[ \clicks ] > 0 ){ ~multiclick };
   if ( ~multiclick[ \clicks ] > 0 ){
      ~multiclick[ \clickDeltas ].add( thisTime - ~multiclick[ \clickTimes ][ ~multiclick[ \clicks ] ] )
   };
   ~multiclick[ \clicks ] = ~multiclick[\clicks] + 1;
   ~multiclick[ \clickTimes ].put( ~multiclick[\clicks], thisTime );
   ~multiclick[ \clickVals ].put( ~multiclick[\clicks], el.value );
   ~multiclick[\timeOut].stop.reset.play;
   ~multiclick.put( \lastTime, thisTime );
   ~multiclick[\clicks].postln;
};
);


(
Ndef( \testSynth, { |amp=1,on=1|
	var trig = Impulse.kr( \rate.kr(1) );
	var seq = Demand.kr( trig, 0, Dseq( \dseq.kr( [0,0,0] ), inf ) );
	SinOsc.ar( seq.exprange( 100, 1000 ), mul: on * amp * EnvGen.kr( Env.perc, trig, timeScale: \dur.kr(0.5) ) );
} );
);
Ndef( \testSynth ).play;

~multiclick[ \clickActions ].put( 1, { |vals,deltas| [ 1, vals, deltas ].postln; Ndef( \testSynth ).set( \amp, vals.at(1) ); } );
~multiclick[ \clickActions ].put( 2, { |vals,deltas| [ 2, vals, deltas.asArray ].postln; Ndef( \testSynth ).set( \dur, deltas.first * 2, \rate, ( deltas.first * 3 ).reciprocal ) } );
~multiclick[ \clickActions ].put( 3, { |vals,deltas| [ 3, vals.asArray, deltas ].postln; Ndef( \testSynth ).setn( \dseq, vals.asArray ); } );

// ------------------ buttons in relationship to each other --------------

// You could extend the concept above to button presses on different buttons, so creating "key-combos", like in games where you have special actions dependent on using a specific control-sequence.


// -------------- modal control, a button press selects a mode for another control --------

// You can also use buttons to select between different modes of control, or to shift control from one controller to another.