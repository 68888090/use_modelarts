import { abilityAccessCtrl, Permissions } from '@kit.AbilityKit'
import { speechRecognizer } from '@kit.CoreSpeechKit'
import { audio } from '@kit.AudioKit'
import { fileIo } from '@kit.CoreFileKit';
import { BusinessError } from '@kit.BasicServicesKit';
import BaiduHttp from '../Utils/BaiduHttp';
import fs from '@ohos.file.fs';
import { AudioCapturerDemo } from '../Utils/PlayMusic';

import picker from '@ohos.file.picker';

// import  from '../Utils/PlayMusic'
//初始设置配置
const TAG = 'AudioCapturerDemo';

class Options {
  offset?: number;
  length?: number;
}

let context = getContext(this);
let bufferSize: number = 0;
let audioCapturer: audio.AudioCapturer | undefined = undefined;
let audioStreamInfo: audio.AudioStreamInfo = {
  samplingRate: audio.AudioSamplingRate.SAMPLE_RATE_16000, // 采样率
  channels: audio.AudioChannel.CHANNEL_1, // 通道
  sampleFormat: audio.AudioSampleFormat.SAMPLE_FORMAT_S16LE, // 采样格式
  encodingType: audio.AudioEncodingType.ENCODING_TYPE_INVALID // 编码格式
}
let audioCapturerInfo: audio.AudioCapturerInfo = {
  source: audio.SourceType.SOURCE_TYPE_MIC, // 音源类型
  capturerFlags: 0 // 音频采集器标志
}
let audioCapturerOptions: audio.AudioCapturerOptions = {
  streamInfo: audioStreamInfo,
  capturerInfo: audioCapturerInfo

}

let path = getContext().cacheDir;
let filePath = path + '/dian1.pcm';
// let filePath1 = 'C:\\Users\\luyu\\Pictures\\gif图库\\16k.pcm'
let file: fileIo.File
let audio1 = new AudioCapturerDemo()


export class AudioUtils{
  static  async init(): Promise<boolean> {
    console.log('start init success');
    console.log('success:'+'path:'+path+',filePath:'+filePath)
    let readDataCallback = await AudioUtils.openFile()
    return new Promise((resolve) => {
      audio.createAudioCapturer(audioCapturerOptions, (err, capturer) => {
        if (err) {
          console.error(`Invoke createAudioCapturer failed, code is ${err.code}, message is ${err.message}`);
          resolve(false);
          return;
        }
        console.info(`${TAG}: create AudioCapturer success`);
        audioCapturer = capturer;

        if (audioCapturer !== undefined) {
          (audioCapturer as audio.AudioCapturer).on('readData', readDataCallback);
          resolve(true);
        } else {
          resolve(false);
        }
      });
    });
  }

  static  async  example() {
    try {
      let DocumentSelectOptions = new picker.DocumentSelectOptions();
      let documentPicker = new picker.DocumentViewPicker();
      documentPicker.select(DocumentSelectOptions, (err, DocumentSelectResult) => {
        if (err) {
          console.error('DocumentViewPicker.select failed with err: ' + err);
          return;
        }
        console.info('DocumentViewPicker.select successfully, DocumentSelectResult uri: ' + JSON.stringify(DocumentSelectResult));
      });
    } catch (err) {
      console.error('DocumentViewPicker failed with err: ' + err);
    }
  }

  static  async openFile(){
    file= fileIo.openSync(filePath, fileIo.OpenMode.READ_WRITE | fileIo.OpenMode.CREATE);

    // let file1 = fs.openSync(filePath, fs.OpenMode.READ_WRITE); // 打开文件

    let stat = fs.statSync(filePath); // 获取文件状态
    console.error("file1.size:"+stat.size) // 打印文件的长度

    let readDataCallback = (buffer: ArrayBuffer) => {
      let options: Options = {
        offset: bufferSize,
        length: buffer.byteLength
      }
      fileIo.writeSync(file.fd, buffer, options);
      bufferSize += buffer.byteLength;
    }
    return readDataCallback
  }

  // 开始一次音频采集
  static  async start() {
    await AudioUtils.init();
    if (audioCapturer !== undefined) {

      let stateGroup = [audio.AudioState.STATE_PREPARED, audio.AudioState.STATE_PAUSED, audio.AudioState.STATE_STOPPED];
      if (stateGroup.indexOf((audioCapturer as audio.AudioCapturer).state.valueOf()) ===
        -1) { // 当且仅当状态为STATE_PREPARED、STATE_PAUSED和STATE_STOPPED之一时才能启动采集
        console.error(`${TAG}: start failed`);
        return;
      }

      // 启动采集
      (audioCapturer as audio.AudioCapturer).start((err: BusinessError) => {
        if (err) {
          console.error('Capturer start failed.');
        } else {
          console.info('Capturer start success.');
        }
      });
    }else{
      console.log('success:audioCapturer undifined')
    }
  }

  // 停止采集
  static  stop() {
    if (audioCapturer !== undefined) {
      // 只有采集器状态为STATE_RUNNING或STATE_PAUSED的时候才可以停止
      if ((audioCapturer as audio.AudioCapturer).state.valueOf() !== audio.AudioState.STATE_RUNNING &&
        (audioCapturer as audio.AudioCapturer).state.valueOf() !== audio.AudioState.STATE_PAUSED) {
        console.info('Capturer is not running or paused');
        return;
      }

      //停止采集
      (audioCapturer as audio.AudioCapturer).stop((err: BusinessError) => {
        if (err) {
          console.error('Capturer stop failed.');
        } else {
          // audioCapturer?.state.toString()

          console.info('Capturer stop success.');
          // start()
        }
      });
    }
  }

  // 销毁实例，释放资源
 static  async  release():Promise<string> {
    return new Promise((resolve,reject)=>{
      if (audioCapturer !== undefined) {
        // 采集器状态不是STATE_RELEASED或STATE_NEW状态，才能release
        if ((audioCapturer as audio.AudioCapturer).state.valueOf() === audio.AudioState.STATE_RELEASED ||
          (audioCapturer as audio.AudioCapturer).state.valueOf() === audio.AudioState.STATE_NEW) {
          console.info('Capturer already released');
          reject();
        }

        //释放资源
        (audioCapturer as audio.AudioCapturer).release((err: BusinessError) => {
          if (err) {
            console.error('Capturer release failed.');
          } else {
            let temp =file.path
            fileIo.close(file);
            // pause()
            let stringTemp = ''
            BaiduHttp.requestVoice(temp,()=>{

            }).then((responseText:string)=>{
              stringTemp = responseText
              fs.unlink(filePath, (err) => {
                if (err) {
                  console.error("remove file failed with error message: " + err.message + ", error code: " + err.code);
                  reject()
                } else {
                  console.error("remove file succeed");


                }

              });
              resolve(stringTemp)
            }
            );





            console.info('Capturer release success.');
          }
        });
      }
    })

  }
}