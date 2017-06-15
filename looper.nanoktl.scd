(
s = Server.default;

// SYNTHS
s.waitForBoot({

	var bufferArray, recSynths, playSynths;
	var bufferDuration; // seconds
	var ktl;
	var recording;
	var rates, amps, prelevels;

	SynthDef(\recbuf, {arg buffer, preLevel=0.5, amp=1;
		var sig = SoundIn.ar(0) * amp;
		RecordBuf.ar(sig, buffer, 0, preLevel:preLevel, loop:1);
	}).send(s);

	SynthDef(\playbuf, {arg buffer, out=0, rate=1, t_trig=1, amp=1;
		var signal;
		signal = PlayBuf.ar(1, buffer, rate:rate, trigger:t_trig, loop:1) * amp;
		Out.ar(out, Pan2.ar(signal, 0));
	}).send(s);


	// LOOPER

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

})
)