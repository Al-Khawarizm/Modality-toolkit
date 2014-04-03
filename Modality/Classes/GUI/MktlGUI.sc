MKtlGUI {

	/*
	MKtlGUI creates a GUI for MKtl instances. All sliders, knobs and buttons etc. are shown in a single window. Note that the layout on the display will not always reflect that of the actual controller, because it is organised according to how the objects are organised in the MKtl description. If devices have multiple "pages" or "scenes", they will all be displayed together in the same window. The GUI elements are updated every 0.2s to reflect the current value of the corresponding MKtlElement. The GUI can also be used as a "virtual controller", as pulling the sliders and pressing the buttons will also change the state of the MKtlElements and fire any connected actions.

	Use case:

	// if a physical NanoKONTROL 2 is present:
	b = MIDIMKtl( 'nnkn20' );

	// if not
	b = MIDIMKtl.make( 'fakeNano2', 'nanoKONTROL2' );

	b.gui; // show the GUI

	*/

	classvar <>makeElementDict;

	var <mktl;
	var <>parent, <>views, <>values, <>getValueFuncs, <>skipJack;

	*new { |parent, bounds, mktl|
		^this.newCopyArgs( mktl ).makeView( parent, bounds );
	}

	*initClass {
		makeElementDict = (
			'button': { |parent, single = false|
				Button( parent, if( single != false ) { 50@16 } { 20@16 })
				.states_([[ "0" ],[ "1", Color.black, Color.gray(0.33) ]]);
			},
			'midiBut': { |parent|
				Button( parent, 20@16 )
				.states_([[ "0" ],[ "1", Color.black, Color.gray(0.33) ]]);
			},
			'slider': { |parent, single = false|
				Slider( parent, if( single != false ) { 100@20 } { 20@80 });
			},
			'encoder': { |parent|
				Knob( parent, 20@20 );
			},
			'knob': { |parent|
				Knob( parent, 20@20 );
			},
			'pad': { |parent|
				Slider( parent, 40@40 ); // make this a slider for now
			},
			'unknown': { |parent|
				NumberBox( parent, 20@16 );
			}
		);
	}

	makeView { |parent, bounds|
		parent = parent ?? { Window( mktl.name, bounds, scroll: true ).front; };

		if( parent.asView.decorator.isNil ) { parent.addFlowLayout };

		views = [];
		values = [];
		getValueFuncs = [];

		this.getSingleElements.sortedKeysValuesDo({ |key, item|
			var view, getValueFunc, value;

			StaticText( parent, 40@16 ).string_( key.asString );

			view = (makeElementDict[ item.type ] ?? { makeElementDict[ \unknown ] }).value( parent, true );

			getValueFunc = { mktl.elementAt( key ).value; };
			value = getValueFunc.value;

			view.value_( value );
			view.action_({ |vw|
				mktl.elementAt( key ).valueAction = vw.value;
			});

			getValueFuncs = getValueFuncs.add( getValueFunc );
			values = values.add( value );
			views = views.add( view );

			parent.asView.decorator.nextLine;
		});

		this.getArrayedElements.sortedKeysValuesDo({ |key, item|
			var view, getValueFunc, value;
			var currentState;

			StaticText( parent, 40@16 ).string_( key.asString );

			mktl.prTraverse.(
				item, [], { |a,b|
					a.asCollection.copy.add( b );
				}, { |state, item|
					var view, getValueFunc, value;

					if( currentState.isNil ) { currentState = state };
					if( currentState.reverse[1].notNil && { currentState.reverse[1] != state.reverse[1] } ) {
						parent.asView.decorator.nextLine;
						parent.asView.decorator.shift( 44, 0 );
					};
					if( currentState.reverse[2].notNil && { currentState.reverse[2] != state.reverse[2] } ) {
						parent.asView.decorator.shift( 0, 5 );
					};
					currentState = state;

					view = (makeElementDict[ item.type ] ?? { makeElementDict[ \unknown ] }).value( parent, false );

					getValueFunc = { mktl.elementAt( key, *state ).value; };
					value = getValueFunc.value;

					view.value_( value );
					view.action_({ |vw|
						mktl.elementAt( key, *state ).valueAction = vw.value;
					});

					getValueFuncs = getValueFuncs.add( getValueFunc );
					values = values.add( value );
					views = views.add( view );
				};
			);

			parent.asView.decorator.nextLine;
		});

		skipJack = SkipJack( { this.updateGUI }, 0.2, { parent.isClosed } );
	}

	getSingleElements {
		^mktl.deviceDescriptionHierarch.select({ |item| item.isKindOf( Array ).not });
	}

	getArrayedElements {
		^mktl.deviceDescriptionHierarch.select({ |item| item.isKindOf( Array ) });
	}

	updateGUI {
		values = values.collect({ |value, i|
			var newValue;
			newValue = getValueFuncs[i].value;
			if( value != newValue ) {
				views[ i ].value = newValue
			};
			newValue;
		});
	}

}

+ MKtl {

	gui { |parent, bounds|
		^MKtlGUI( parent, bounds, this );
	}

}