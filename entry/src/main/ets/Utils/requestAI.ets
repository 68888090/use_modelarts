import { http } from '@kit.NetworkKit';
import { BusinessError, UploadResponse } from '@kit.BasicServicesKit';
import fs from '@ohos.file.fs';
import request from '@ohos.request';

export interface DetectionResponse {
  detection_classes: Array<string>;
  detection_boxes: Array<Array<number>>;
  detection_scores: Array<number>;  // 假设为数字数组，根据实际情况调整
}


export class RequestAI {

  url:string =''
  appCode:string =''
  filePath:string=''
  fileName:string = ''
  copyFilePath:string = ''
  httpRequest = http.createHttp()

  constructor (url: string, filePath: string,appCode:string) {
    this.url = url
    this.appCode = appCode
    this.filePath = filePath
    this.httpRequest.on('headersReceive', (header) => {
      console.info('header: ' + JSON.stringify(header));
    });
    const context = getContext(this)
    const fileType = 'jpg'
    // （以时间戳）生成一个新的文件名
     this.fileName = Date.now() + '.' + fileType
    // 通过缓存路径+文件名 拼接出完整的路径
     this.copyFilePath = context.cacheDir + '/' + this.fileName
    // 将文件 拷贝到 临时目录
    const file = fs.openSync(this.filePath, fs.OpenMode.READ_ONLY)
    fs.copyFileSync(file.fd, this.copyFilePath)
  }

  async PostAI(): Promise<DetectionResponse> {
    return new Promise<DetectionResponse>((resolve, reject) => {
      request.uploadFile(getContext(), {
        method: 'POST',
        url: this.url,
        header: {
          'Content-Type': 'multipart/form-data',
          'X-Apig-AppCode': this.appCode
        },
        files: [{ filename: this.fileName, type: 'jpg', name: 'img', uri: this.copyFilePath }],
        data: []
      }).then(res => {

        // 监听上传进度
        res.on('progress', (uploaderSize, totalSize) => {
          if (uploaderSize === totalSize) {
            AlertDialog.show({ message: "上传成功" });
          }
        });

        // 监听上传成功后服务器返回的响应头信息
        res.on('headerReceive', (value) => {
          try {
            let uploadRes = value as UploadResponse;
            let response = JSON.parse(uploadRes.data) as DetectionResponse;
            resolve(response);  // 返回解析后的 JSON 数据
          } catch (error) {
            reject(new Error("Failed to parse JSON response."));
          }
        });

      }).catch((err: BusinessError) => {
        console.error(`Failed to upload image. Code is ${err.code}, message is ${err.message}`);
        reject(err);
      });
    });
  }

}