package snow.modules.howlerjs;

import snow.modules.howlerjs.Howl;
import snow.types.Types;
import snow.api.Promise;
import snow.api.buffers.Uint8Array;

typedef Sound = snow.modules.howlerjs.sound.Sound;

@:allow(snow.system.audio.Audio)
class Audio implements snow.modules.interfaces.Audio {

    var suspended_sounds : Array<snow.system.audio.Sound>;
    var system : snow.system.audio.Audio;
    var handles : Map<Howl, Sound>;

    function new( _system:snow.system.audio.Audio ) {
        system = _system;
        suspended_sounds = [];
        handles = new Map();
    }

    function init() {}
    function update() {}
    function destroy() {}
    function on_event( event:SystemEvent ) {}

    public function suspend() {

        for(sound in handles) {
            if(sound.playing) {
                sound.toggle();
                suspended_sounds.push(sound);
            }
        }

    } //suspend

    public function resume() {

        while(suspended_sounds.length > 0) {
            var sound = suspended_sounds.pop();
            sound.toggle();
        }

    } //resume

    function info_from_id(_id:String, ?_format:AudioFormatType) : AudioInfo {

        if(_format == null) {
            var _ext = haxe.io.Path.extension(_id);
            _format = switch(_ext) {
                case 'wav': wav;
                case 'ogg': ogg;
                case 'pcm': pcm;
                case _: unknown;
            }
        }

        return {
            format: _format,
            id:_id,
            handle:null,
            data:null
        }

    } //info_from_id

    public function create_sound( _id:String, _name:String, _streaming:Bool=false, ?_format:AudioFormatType ) : Promise {

        return new Promise(function(resolve, reject) {

            var _path = system.app.assets.path(_id);
            var info = info_from_id(_path, _format);
            var sound = new Sound(system, _name, _streaming);

            info.handle = new Howl({
                urls: [ _path ],
                // buffer : _streaming, //:todo: test
                    //we want an end notification to propagate
                onend : function() { system.app.audio.module._on_end(info.handle); },
                    //handle failure
                onloaderror : function() { reject(Error.error('failed to create sound $_name from $_id')); },
                    //and we listen for when it's done loading so we can emit
                onload : function(){
                    info.handle = untyped __js__('this');
                    sound.info = info;
                    handles.set(info.handle, sound);
                    resolve(sound);
                }
            });

        }); //promise

    } //create_sound

    public function create_sound_from_bytes( _name:String, _bytes:Uint8Array, _format:AudioFormatType ) : Sound {
        //:todo:
        throw Error.error('unimplemented / wip');
    }

    //called when a sound ends, due to a bug in chrome with web audio
    //and howler we increased the duration to a really high number,
    //see https://github.com/goldfire/howler.js/issues/279
    //this duration fix from goldfire was implemented in howler locally,
    //but there is an outstanding bug where on end only fires once, not each loop.
    //to make it fire each loop (at the cost of a slight jump on loop)
    //uncomment the stop/play here.

    function _on_end( handle:AudioHandle ) {
        var sound = handles.get(handle);
        if(sound != null) {
            sound.emit('end');

            //:todo: read above
            // sound.stop();
            // sound.play();
        }
    }

} //AudioSystem
