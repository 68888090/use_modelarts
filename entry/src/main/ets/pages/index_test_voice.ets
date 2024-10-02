import { abilityAccessCtrl, Permissions } from '@kit.AbilityKit'
import { speechRecognizer } from '@kit.CoreSpeechKit'
import { audio } from '@kit.AudioKit'
import { fileIo } from '@kit.CoreFileKit';
import { BusinessError } from '@kit.BasicServicesKit';
import BaiduHttp from '../Utils/BaiduHttp';
import fs from '@ohos.file.fs';
import { AudioCapturerDemo } from '../Utils/PlayMusic';
import { router } from '@kit.ArkUI';
import picker from '@ohos.file.picker';

let path = getContext().cacheDir;
let filePath = path + '/dian1.pcm';
let file: fileIo.File
let file2: fileIo.File

//播放器配置
const TAG2 = 'AudioRendererDemo';
class Options2 {
  offset?: number;
  length?: number;
}
let renderModel: audio.AudioRenderer | undefined = undefined;
let audioStreamInfo: audio.AudioStreamInfo = {
  samplingRate: audio.AudioSamplingRate.SAMPLE_RATE_16000, // 采样率
  channels: audio.AudioChannel.CHANNEL_2, // 通道
  sampleFormat: audio.AudioSampleFormat.SAMPLE_FORMAT_S16LE, // 采样格式
  encodingType: audio.AudioEncodingType.ENCODING_TYPE_RAW // 编码格式
}
let audioRendererInfo: audio.AudioRendererInfo = {
  usage: audio.StreamUsage.STREAM_USAGE_MUSIC, // 音频流使用类型
  rendererFlags: 0 // 音频渲染器标志
}
let audioRendererOptions: audio.AudioRendererOptions = {
  streamInfo: audioStreamInfo,
  rendererInfo: audioRendererInfo
}
let writeDataCallback: (buffer: ArrayBuffer) => void

// let writeDataCallback = (buffer: ArrayBuffer) => {
//   let options: Options2 = {
//     offset: bufferSize,
//     length: buffer.byteLength
//   }
//   fileIo.readSync(file2.fd, buffer, options);
//   bufferSize += buffer.byteLength;
// }

//录音器配置
const TAG = 'AudioCapturerDemo';
class Options {
  offset?: number;
  length?: number;
}
let context = getContext(this);
let bufferSize: number = 0;
let audioCapturer: audio.AudioCapturer | undefined = undefined;
// let audioStreamInfo: audio.AudioStreamInfo = {
//   samplingRate: audio.AudioSamplingRate.SAMPLE_RATE_48000, // 采样率
//   channels: audio.AudioChannel.CHANNEL_2, // 通道
//   sampleFormat: audio.AudioSampleFormat.SAMPLE_FORMAT_S16LE, // 采样格式
//   encodingType: audio.AudioEncodingType.ENCODING_TYPE_RAW // 编码格式
// }
let audioCapturerInfo: audio.AudioCapturerInfo = {
  source: audio.SourceType.SOURCE_TYPE_MIC, // 音源类型
  capturerFlags: 0 // 音频采集器标志
}
let audioCapturerOptions: audio.AudioCapturerOptions = {
  streamInfo: audioStreamInfo,
  capturerInfo: audioCapturerInfo

}

let audio1 = new AudioCapturerDemo()
//
// let stat = fs.statSync(filePath); // 获取文件状态
// console.error("file1.size:"+stat.size) // 打印文件的长度

let readDataCallback = (buffer: ArrayBuffer) => {
  let options: Options = {
    offset: bufferSize,
    length: buffer.byteLength
  }
  fileIo.writeSync(file.fd, buffer, options);
  bufferSize += buffer.byteLength;
}

@Entry
@Component
struct Index {
  build() {
    Column({ space: 20 }) {
      Button('开始录音')
        .onClick(() => {
          //注意这里每次都init了一下
          this.start();
        // this.example();
        })

      Button('录音结束')
        .onClick(() => {
          this.stop();
        })

      Button('退出录音')
        .onClick(() => {
          this.release();
          // 跳转到第1页
          // router.pushUrl({ url: 'pages/Index' }).then(() => {
          //   console.info('Succeeded in jumping to the first page.')
          // }).catch((err:Error) => {
          //   console.error(`Failed to jump to the first page,error message is ${err.message}`)
          // })
        })

      Button('返回主页')
        .onClick(() => {
          // 跳转到第1页
          router.pushUrl({ url: 'pages/Index' }).then(() => {
            console.info('Succeeded in jumping to the first page.')
          }).catch((err:Error) => {
            console.error(`Failed to jump to the first page,error message is ${err.message}`)
          })
        })

      Button('播放录音')
        .onClick(async ()=>{
          this.start2();
        })
      Button('结束录音')
        .onClick(async ()=>{
          await this.stop2();
          await this.release2();
        })
    }
    .padding({top:100})
    .width('100%')
    .height('100%')
  }

  // 初始化，创建实例，设置监听事件
  async init(): Promise<boolean> {
    console.log('start init success');
    console.log('success:'+'path:'+path+',filePath:'+filePath)
    try{
      file= fileIo.openSync(filePath, fileIo.OpenMode.READ_WRITE | fileIo.OpenMode.CREATE);
    } catch (e) {
      console.error('error:'+e)
    }
    let readDataCallback = await this.openFile()
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

  async  example() {
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

  async openFile(){
     // file= fileIo.openSync(filePath, fileIo.OpenMode.READ_WRITE | fileIo.OpenMode.CREATE);

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
   async start() {
    await this.init();
     if (!file) {
       console.error('Failed to open file.');
     }
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
  stop() {
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
  release() {
    if (audioCapturer !== undefined) {
      // 采集器状态不是STATE_RELEASED或STATE_NEW状态，才能release
      if ((audioCapturer as audio.AudioCapturer).state.valueOf() === audio.AudioState.STATE_RELEASED ||
        (audioCapturer as audio.AudioCapturer).state.valueOf() === audio.AudioState.STATE_NEW) {
        console.info('Capturer already released');
        return;
      }

      //释放资源
      (audioCapturer as audio.AudioCapturer).release((err: BusinessError) => {
        if (err) {
          console.error('Capturer release failed.');
        } else {

          // let testPath = 'storage/media/100/local/files/Docs/Download/16k.pcm';
          let temp = file.path
          // let temp =file.path
          fileIo.close(file);
          // pause()
          BaiduHttp.requestVoice(temp,(responseText:string)=>{
            // this.messageArray.push(new MessageVOImpl(MessageRoleEnum.Other, responseText)) // 展示对方对话
            // this.scroller.scrollEdge(Edge.Bottom)
          })
            .then(()=>{
            fs.unlink(filePath, (err) => {
              if (err) {
                console.error("remove file failed with error message: " + err.message + ", error code: " + err.code);
              } else {
                console.error("remove file succeed");
              }
            });
          }
          );

          console.info('Capturer release success.');
        }
      });
    }
  }

  // 初始化，创建实例，设置监听事件
  async init2() : Promise<boolean> {
     console.info('start rendering')

    // //测试播放举例音频
    // try{
    // const fileType = 'pcm'
    // // （以时间戳）生成一个新的文件名
    // let fileName = Date.now() + '.' + fileType
    // let temp =        "file://docs/storage/Users/currentUser/Download/16k.pcm"
    // let file3 = fileIo.openSync(temp, fileIo.OpenMode.READ_ONLY)
    // let fileTemp = fileIo.openSync(getContext().filesDir+'/'+fileName,fileIo.OpenMode.READ_WRITE|fileIo.OpenMode.CREATE);
    // fileIo.copyFileSync(file3.fd, fileTemp.fd)
    // let uri = fileTemp.path
    // fileIo.closeSync(file3)
    // fileIo.closeSync(fileTemp)
    //   file2 = fileIo.openSync(uri, fileIo.OpenMode.READ_ONLY)
    // } catch (e) {
    //   console.error('error:'+e)
    // }
    // console.log('transition end')

    try{
      file2 = fileIo.openSync(filePath, fileIo.OpenMode.READ_ONLY);
    } catch (e) {
      console.error('error:'+e)
    }
    writeDataCallback = (buffer: ArrayBuffer) => {
      let options: Options2 = {
        offset: bufferSize,
        length: buffer.byteLength
      }
      fileIo.readSync(file2.fd, buffer, options);
      bufferSize += buffer.byteLength;
    }
    return new Promise((resolve) =>{
      audio.createAudioRenderer(audioRendererOptions, (err, renderer) => { // 创建AudioRenderer实例
        if (!err) {
          console.info(`${TAG2}: creating AudioRenderer success`);
          renderModel = renderer;
          if (renderModel !== undefined) {
            (renderModel as audio.AudioRenderer).on('writeData', writeDataCallback);
            resolve(true)
          }else if(renderModel==undefined){
            console.error('renderModel undefined')
            resolve(false)
          }
        } else {
          console.info(`${TAG2}: creating AudioRenderer failed, error: ${err.message}`);
          return
        }
      });
    })
}

  // 开始一次音频渲染
  async start2() {
  await this.init2();
  let currentSpeed = renderModel?.getVolume()
    console.error('now speed:'+currentSpeed?.toString())

  if (renderModel !== undefined) {
    renderModel?.setSpeed(0.2)
    console.error('Renderer defined!')
    let stateGroup = [audio.AudioState.STATE_PREPARED, audio.AudioState.STATE_PAUSED, audio.AudioState.STATE_STOPPED];
    if (stateGroup.indexOf((renderModel as audio.AudioRenderer).state.valueOf()) === -1) { // 当且仅当状态为prepared、paused和stopped之一时才能启动渲染
      console.error(TAG2 + 'start failed');
      return;
    }
    // 启动渲染
    (renderModel as audio.AudioRenderer).start((err: BusinessError) => {
      if (err) {
        console.error('Renderer start failed.');
      } else {
        console.info('Renderer start success.');
      }
    });
  }else(
    console.error('renderer undefined!')
  )
}

  // 暂停渲染
  pause2() {
  if (renderModel !== undefined) {
    // 只有渲染器状态为running的时候才能暂停
    if ((renderModel as audio.AudioRenderer).state.valueOf() !== audio.AudioState.STATE_RUNNING) {
      console.info('Renderer is not running');
      return;
    }
    // 暂停渲染
    (renderModel as audio.AudioRenderer).pause((err: BusinessError) => {
      if (err) {
        console.error('Renderer pause failed.');
      } else {
        console.info('Renderer pause success.');
      }
    });
  }
}

  // 停止渲染
  async stop2() {
  if (renderModel !== undefined) {
    // 只有渲染器状态为running或paused的时候才可以停止
    if ((renderModel as audio.AudioRenderer).state.valueOf() !== audio.AudioState.STATE_RUNNING && (renderModel as audio.AudioRenderer).state.valueOf() !== audio.AudioState.STATE_PAUSED) {
      console.info('Renderer is not running or paused.');
      return;
    }
    // 停止渲染
    (renderModel as audio.AudioRenderer).stop((err: BusinessError) => {
      if (err) {
        console.error('Renderer stop failed.');
      } else {
        fileIo.close(file2);
        console.info('Renderer stop success.');
      }
    });
  }
}

  // 销毁实例，释放资源
  async release2() {
  if (renderModel !== undefined) {
    // 渲染器状态不是released状态，才能release
    if (renderModel.state.valueOf() === audio.AudioState.STATE_RELEASED) {
      console.info('Renderer already released');
      return;
    }
    // 释放资源
    (renderModel as audio.AudioRenderer).release((err: BusinessError) => {
      if (err) {
        console.error('Renderer release failed.');
      } else {
        console.info('Renderer release success.');
        fs.unlink(filePath, (err) => {
            });
      }
    });
  }
}
}
