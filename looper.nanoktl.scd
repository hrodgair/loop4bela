// SERVER
/*(
s.options.inDevice = "Built-in Microph";
s.options.outDevice = "Built-in Output";
Loopier.boot
)*/
/// !!! TODO: CHANGE TO s.boot
Loopier.boot

// SYNTHS
// !!! TODO: Store SynthDefs in server
(
SynthDef(\recbuf, {arg buffer, preLevel=0.5, amp=1;
	var sig = SoundIn.ar(0) * amp;
	RecordBuf.ar(sig, buffer, 0, preLevel:preLevel, loop:1);
}).add;

SynthDef(\playbuf, {arg buffer, out=0, rate=1, t_trig=1, amp=1;
	var signal;
	signal = PlayBuf.ar(1, buffer, rate:rate, trigger:t_trig, loop:1) * amp;
	Out.ar(out, Pan2.ar(signal, 0));
}).add;
)

// LOOPER
// !!! TODO: auto play at boot
(
var bufferArray, recSynths, playSynths;
var bufferDuration; // seconds
var ktl;
var recording;
var rates, amps, prelevels;

bufferDuration = 4.0;
bufferArray = Array.fill(8, { Buffer.alloc(s, s.sampleRate * bufferDuration, 1)});
recSynths = Array.fill(8, { nil });
playSynths = Array.fill(8, { nil });

rates = Array.fill(8, 1);
amps = Array.fill(8, 1);
prelevels = Array.fill(8, 1);

ktl = NanoKtl.new;
8.do({|i|

 	// NANO KTL
	// Recording
 	ktl.mapCCS(4, ('bu'++i).asSymbol, {|val|
		"REC: sc 1, bu %: %.\n".postf(i,[val]) ;
		if(val > 0, {
			"recording".postln;
			recording = true;
			recSynths[i] = Synth(\recbuf, [\buffer, bufferArray[i]]);
		},{
			"stop recording synth".postln;
			recording = false;
			recSynths[i].free;
		})
 	});
	// Playing
	ktl.mapCCS(4, ('bd'++i).asSymbol, {|val|
 		"sc 1, bd %: %.\n".postf(i,[val]) ;
		if(val > 0, {
			"playing".postln;
			playSynths[i] = Synth(\playbuf, [\buffer, bufferArray[i], \rate, rates[i]]);
		},{
			"stop synth".postln;
			playSynths[i].free;
		})
 	});
	// Rate
 	ktl.mapCCS(4, ('sl'++i).asSymbol, {|val|
			val = val.linlin(0,127,-2, 2);
			"RATE: sc 1, sl %: %.\n".postf(i,[val]) ;
		rates[i] = val;
			playSynths[i].set(\rate, rates[i]);
 	});
	// Volume
 	ktl.mapCCS(4, ('kn'++i).asSymbol, {|val|
		var value = val.linlin(0,127,0,1.1);
			"AMP: sc 1, kn %: %.\n".postf(i,[val]) ;
		if(recording, {
			prelevels[i] = value;
			"PRELEVEL: %".postf(prelevels[i]);
			recSynths[i].set(\preLevel, prelevels[i])
		},{
			amps[i] = value * 2;
			"AMP: %".postf(value);
			playSynths[i].set(\amp, amps[i])
		})
 	});
 });

// SYNC all players
ktl.mapCCS(0, 'rec', {
	|ch, cc, val| " 'rec': %.\n".postf([ch, cc, val]);
	8.do( {|i| playSynths[i].set(\t_trig, 1)});
});
/*


w = Window.new("recbuffs", Rect(10, 10, 500, 300)).front;
8.do({arg i;
	// rec buttons
	Button.new(w, Rect(10+(i*60), 10, 50, 20))
	.states_([["Record"],["Stop"]])
	.action_({arg butt;
		if(butt.value == 1, {
			"recording".postln;
			recSynths[i] = Synth(\recbuf, [\buffer, bufferArray[i]]);
		},{
			"stop synth".postln;
			recSynths[i].free;
		})
	});

	// play buttons
	Button.new(w, Rect(10+(i*60), 40, 50, 20))
	.states_([["Play"],["Stop"]])
	.action_({arg butt;
		if(butt.value == 1, {
			"playing".postln;
			playSynths[i] = Synth(\playbuf, [\buffer, bufferArray[i], \rate, 1]);
		},{
			"stop synth".postln;
			playSynths[i].free;
		})
	});

	// clear buttons
	Button.new(w, Rect(10+(i*60), 70, 50, 20))
	.states_([["Clear"]])
	.action_({arg butt;
		if(butt.value == 1, {
			"stop synth".postln;
			playSynths[i].free;
		})
	});

	Slider.new(w, Rect(10+(i*60), 100, 50, 200))
	.orientation_(\vertical)
	.value_(0.5)
	.action_({|sl|
		sl.value.linlin(0,1,-2,2).postln;
		playSynths[i].set(\rate, sl.value.linlin(0,1,-2,2));
	});
});

Button.new(w, Rect(10, 300, 70, 50))
	.states_([["DEBUG"],["Stop"]])
	.action_({arg butt;
			"debug".postln;
			[\bufferArray, bufferArray].postln;
			[\recSynths, recSynths].postln;
			[\playSynths, playSynths].postln;
	});
*/
)