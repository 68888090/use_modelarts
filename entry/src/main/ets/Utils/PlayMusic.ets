import audio from'@ohos.multimedia.audio';
import { BusinessError } from'@ohos.base';
import fs from'@ohos.file.fs';



const TAG ='AudioUtils';


export class AudioCapturerDemo {
  private audioCapturer: audio.AudioCapturer | undefined = undefined;
  private audioStreamInfo: audio.AudioStreamInfo = {
    samplingRate: audio.AudioSamplingRate.SAMPLE_RATE_44100,
    channels: audio.AudioChannel.CHANNEL_1,
    sampleFormat: audio.AudioSampleFormat.SAMPLE_FORMAT_S16LE,
    encodingType: audio.AudioEncodingType.ENCODING_TYPE_RAW
  }
  private audioCapturerInfo: audio.AudioCapturerInfo = {
    source: audio.SourceType.SOURCE_TYPE_MIC,
    capturerFlags: 0
  }

  async createAudioCapturer() {
    let audioCapturerOptions: audio.AudioCapturerOptions = {
      streamInfo: this.audioStreamInfo,
      capturerInfo: this.audioCapturerInfo
    }
    this.audioCapturer = await audio.createAudioCapturer(audioCapturerOptions);
    if (this.audioCapturer == undefined) {
      console.error('createAudioCapturer failed');
      return;
    }
    console.info('createAudioCapturer success');
  }

  async  startAudioCapturer() {
    if (this.audioCapturer !== undefined) {
      await this.audioCapturer.start();
      console.info('Capturer started');
    }
  }

  async  releaseAudioCapturer() {
    if (this.audioCapturer !== undefined) {
      await this.audioCapturer.stop();
      await this.audioCapturer.release();
      this.audioCapturer = undefined;
      console.info('Capturer released');
    }
  }

  public static async writeAudioToFile(filePath: string, audioBuffer: ArrayBuffer): Promise<void> {
    let file: fs.File;
    try {
      file = fs.openSync(filePath, fs.OpenMode.READ_WRITE | fs.OpenMode.CREATE);
    } catch (err) {
      console.error(TAG, `openSync failed, code is ${err.code}, message is ${err.message}`);
      return;
    }

    let writeLen: number = 0;
    try {
      writeLen = fs.writeSync(file.fd, audioBuffer);
    } catch (err) {
      console.error(TAG, `writeSync failed, code is ${err.code}, message is ${err.message}`);
    }
    fs.closeSync(file);
    console.info(TAG, `write audio data to file succeed and size is: ${writeLen}`);
  }


}
