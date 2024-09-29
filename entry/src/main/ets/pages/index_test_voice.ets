import { abilityAccessCtrl, Permissions } from '@kit.AbilityKit'
import { speechRecognizer } from '@kit.CoreSpeechKit'
import { audio } from '@kit.AudioKit'
import { fileIo } from '@kit.CoreFileKit';
import { BusinessError } from '@kit.BasicServicesKit';
import BaiduHttp from '../Utils/BaiduHttp';
import fs from '@ohos.file.fs';
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
  samplingRate: audio.AudioSamplingRate.SAMPLE_RATE_48000, // 采样率
  channels: audio.AudioChannel.CHANNEL_2, // 通道
  sampleFormat: audio.AudioSampleFormat.SAMPLE_FORMAT_S16LE, // 采样格式
  encodingType: audio.AudioEncodingType.ENCODING_TYPE_RAW // 编码格式
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
let filePath = path + '/StarWars10s-2C-48000-4SW11.pcm';
let file: fileIo.File = fileIo.openSync(filePath, fileIo.OpenMode.READ_WRITE | fileIo.OpenMode.CREATE);

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

@Entry
@Component
  // struct Index {
  //   audioCapturer: audio.AudioCapturer | null = null
  //   asrEngine: speechRecognizer.SpeechRecognitionEngine | null = null
  //   asrEngineId: string = 'QF'
  //   @State str: string = ""
  //
  //   build() {
  //     Column({ space: 20 }) {
  //       Text('结果:' + this.str)
  //
  //       Button('开始识别')
  //         .onClick(() => {
  //           this.startRecord()
  //         })
  //
  //       Button('识别结束')
  //         .onClick(() => {
  //           this.closeRecord()
  //         })
  //     }
  //     .width('100%')
  //     .height('100%')
  //   }
  //
  //   async requestPermissions(permissions: Permissions[]) {
  //     // 1. 创建应用权限管理器
  //     const atManager = abilityAccessCtrl.createAtManager()
  //     // 2. 向用户申请 user_grant 权限（温馨提示：首次申请时会弹窗，后续申请则不会再出现弹窗）
  //     const requestResult = await atManager.requestPermissionsFromUser(getContext(), permissions)
  //     // 通过 every 检查权限是否都成功授权
  //     const isAuth = requestResult.authResults.every(item => item === abilityAccessCtrl.GrantStatus.PERMISSION_GRANTED)
  //     // Promise.resolve()   返回 Promise 成功，await 后续代码，正常执行
  //     // Promise.reject()    返回 Promise 错误，Promise.reject() 的结果可被 catch 捕获
  //     return isAuth === true ? Promise.resolve(true) : Promise.reject(false)
  //   }
  //
  //   // 开始录制
  //   async startRecord() {
  //     // 1. 初始化语音识别引擎
  //     this.asrEngine = await speechRecognizer.createEngine({
  //       language: 'zh-CN',
  //       online: 1
  //     })
  //     // 保存组件的 this，后续通过_this来使用组件
  //     const _this = this
  //     // 2. 给引擎设置回调(监听)，用来接收语音识别相关的回调信息
  //     this.asrEngine.setListener({
  //       onStart(sessionId: string, eventMessage: string) {
  //         console.error(`识别开始：onStart, sessionId: ${sessionId} eventMessage: ${eventMessage}`);
  //       },
  //       onEvent(sessionId: string, eventCode: number, eventMessage: string) {
  //         console.error(`onEvent, sessionId: ${sessionId} eventCode: ${eventCode} eventMessage: ${eventMessage}`);
  //       },
  //       // !! 识别结果回调，包括中间结果和最终结果
  //       onResult(sessionId: string, result: speechRecognizer.SpeechRecognitionResult) {
  //         _this.str = result.result
  //         // _this.onChange(result.result)
  //         console.error(`识别完成：onResult, sessionId: ${sessionId} sessionId: ${JSON.stringify(result)}`);
  //       },
  //       // 识别完成回调
  //       onComplete(sessionId: string, eventMessage: string) {
  //         // 录音完成，修改录音状态，更新视图，隐藏录音提示文案
  //         console.error(`onComplete, sessionId: ${sessionId} eventMessage: ${eventMessage}`);
  //       },
  //       onError(sessionId: string, errorCode: number, errorMessage: string) {
  //         console.error(`onError, sessionId: ${sessionId} errorCode: ${errorCode} errorMessage: ${errorMessage}`);
  //       }
  //     })
  //
  //     // 3. 调用 startListening 方法，开始合成
  //     this.asrEngine?.startListening({
  //       sessionId: this.asrEngineId,
  //       audioInfo: {
  //         audioType: 'pcm',
  //         sampleRate: 16000,
  //         soundChannel: 1,
  //         sampleBit: 16
  //       }
  //     })
  //     // 开始录音
  //     const audioStreamInfo: audio.AudioStreamInfo = {
  //       samplingRate: audio.AudioSamplingRate.SAMPLE_RATE_16000,
  //       channels: audio.AudioChannel.CHANNEL_1,
  //       sampleFormat: audio.AudioSampleFormat.SAMPLE_FORMAT_S16LE,
  //       encodingType: audio.AudioEncodingType.ENCODING_TYPE_RAW
  //     }
  //     const audioCapturerInfo: audio.AudioCapturerInfo = {
  //       source: audio.SourceType.SOURCE_TYPE_MIC,
  //       capturerFlags: 0
  //     }
  //     const audioCapturerOptions: audio.AudioCapturerOptions = {
  //       streamInfo: audioStreamInfo,
  //       capturerInfo: audioCapturerInfo
  //     }
  //     // 4. 获取音频采集器
  //     this.audioCapturer = await audio.createAudioCapturer(audioCapturerOptions)
  //     this.audioCapturer.on('readData', (buffer) => {
  //       // 5. 调用 writeAudio 方法，开始写入音频流。读取音频文件时，开发者需预先准备一个pcm格式音频文件。
  //       this.asrEngine?.writeAudio(this.asrEngineId, new Uint8Array(buffer))
  //       console.debug('开始写入音频')
  //     })
  //     await this.audioCapturer.start()
  //   }
  //
  //   // 停止录制
  //   async closeRecord() {
  //     this.audioCapturer?.stop()
  //     this.audioCapturer?.release()
  //     // 结束识别，调用 finish 方法
  //     this.asrEngine?.finish(this.asrEngineId)
  //     // 取消识别，调用 cancel 方法
  //     this.asrEngine?.cancel(this.asrEngineId)
  //     // 释放语音识别引擎资源，调用shutdown方法
  //     this.asrEngine?.shutdown()
  //
  //   }
  //
  //   aboutToAppear(): void {
  //     // 申请麦克风权限弹窗
  //     this.requestPermissions(["ohos.permission.MICROPHONE"])
  //   }
  // }
struct Index {
  build() {
    Column({ space: 20 }) {
      Button('开始录音')
        .onClick(() => {
          //注意这里每次都init了一下
          this.start();
        })

      Button('录音结束')
        .onClick(() => {
          this.stop();
        })

      Button('退出录音')
        .onClick(() => {
          this.release();
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

  // 开始一次音频采集
  async start() {
    await this.init();
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
          let temp =file.path
          fileIo.close(file);
          BaiduHttp.requestVoice(temp,(responseText:string)=>{
            // this.messageArray.push(new MessageVOImpl(MessageRoleEnum.Other, responseText)) // 展示对方对话
            // this.scroller.scrollEdge(Edge.Bottom)
          });
          console.info('Capturer stop success.');
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
          console.info('Capturer release success.');
        }
      });
    }
  }
}
