import { http } from '@kit.NetworkKit';
import { BusinessError, UploadResponse } from '@kit.BasicServicesKit';
import fs from '@ohos.file.fs';
import request from '@ohos.request';
import promptAction from '@ohos.promptAction';

export interface DetectionResponse {
  detection_classes: Array<string>;
  detection_boxes: Array<Array<number>>;
  detection_scores: Array<number>;  // 假设为数字数组，根据实际情况调整
}


interface GeneratedObjectLiteralInterface_2 {
  name: string;
  ContentType: string;
  filePath: string;
}

export let responseString : string

export class RequestAI {

  url:string =''
  appCode:string =''
  filePath:string=''
  fileName:string = ''
  copyFilePath:string = ''
  imageuri:string = ''


  constructor (filePath: string,url = "https://infer-app-modelarts-cn-southwest-2.myhuaweicloud.com/v1/infers/4aef5d61-24cc-41fd-b1d6-ef307e9852ca",
    appCode="ab4be939eff64a4a9edb18898ee2277f3c0c97d2c21e420b83d87ef54e3b9113") {
    this.url = url
    this.appCode = appCode
    this.filePath = filePath
    const context = getContext(this)
    const fileType = 'jpg'
    // （以时间戳）生成一个新的文件名
     this.fileName = Date.now() + '.' + fileType
    // 通过缓存路径+文件名 拼接出完整的路径
     this.copyFilePath = context.cacheDir + '/' + this.fileName
    // 将文件 拷贝到 临时目录


    const file = fs.openSync(this.filePath, fs.OpenMode.READ_ONLY)


    let fileTemp = fs.openSync(getContext().filesDir+file.name,fs.OpenMode.READ_WRITE|fs.OpenMode.CREATE);
    this.imageuri  = fileTemp.path

    fs.copyFileSync(file.fd, fileTemp.fd)
    fs.closeSync(file)
    fs.closeSync(fileTemp)
  }

  async PostAI(){

     try{
       let httpRequest = http.createHttp()
       httpRequest.on('headersReceive', (header) => {
         console.info('header: ' + JSON.stringify(header));
       });
       promptAction.showToast({
         message: '数据传输中！'//弹窗内容
       })
       httpRequest.request(
         this.url,
         {
           method:http.RequestMethod.POST,
           header:{
             'Content-Type':'multipart/form-data',
             'X-Apig-AppCode':this.appCode
           },
           expectDataType:http.HttpDataType.STRING,
           multiFormDataList:[{
             name:'file',
             contentType:'image/jpg',
             filePath:this.imageuri,
             remoteFileName: '200.png'
           }],


         },(err:BusinessError,data:http.HttpResponse)=>{
           if(!err){
             promptAction.showToast({
               message: '数据传输成功'//弹窗内容
             })
             // data.result为HTTP响应内容，可根据业务需要进行解析
            responseString = data.result.toString()
             console.error('Result:' + data.result);
             console.error('code:' + JSON.stringify(data.responseCode));
             // data.header为HTTP响应头，可根据业务需要进行解析
             console.error('header:' + JSON.stringify(data.header));
             console.error('cookies:' + JSON.stringify(data.cookies)); //

             console.log("test:上传结束")

             httpRequest.destroy()
           } else {
             console.error('error:' + JSON.stringify(err));
             // 取消订阅HTTP响应头事件
             httpRequest.off('headersReceive');
             // 当该请求使用完毕时，调用destroy方法主动销毁
             httpRequest.destroy();
           }

       }

       )
     }catch (err){
       console.error(err)
     }
  }
}