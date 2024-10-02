import { http } from '@kit.NetworkKit';
import { BusinessError, UploadResponse } from '@kit.BasicServicesKit';
import fs from '@ohos.file.fs';
import request from '@ohos.request';
import promptAction from '@ohos.promptAction';
import * as PriData from './Pri_data';

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
  exout : PriData.GG =  {width:0,height:0,data:''}

//API：https://infer-app-modelarts-cn-southwest-2.myhuaweicloud.com/v1/infers/31fb80a1-dd43-4648-b251-7b6e0d9bd2dd
//   constructor (filePath: string,url = "https://infer-app-modelarts-cn-southwest-2.myhuaweicloud.com/v1/infers/4aef5d61-24cc-41fd-b1d6-ef307e9852ca",

  constructor (filePath: string,url = "https://infer-app-modelarts-cn-southwest-2.myhuaweicloud.com/v1/infers/31fb80a1-dd43-4648-b251-7b6e0d9bd2dd",
    appCode="827d6fb7c5154a1ca665927bc35984d43b4677fbe4b34705857bc6d417275ff8") {
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
    PriData.getImageSize(fileTemp.path).then((temp:PriData.GeneratedTypeLiteralInterface_1)=>{
      this.exout.width = temp.width
      this.exout.height = temp.height
    })
    console.error('filePath '+filePath+' Height:'+this.exout.height+' width ' +this.exout.width);



    fs.copyFileSync(file.fd, fileTemp.fd)
    fs.closeSync(file)
    fs.closeSync(fileTemp)
  }

    PostAI():Promise<PriData.GG>{
      return new Promise((resolve,reject)=>{
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
              console.error('Result:' + responseString);
              console.error('code:' + JSON.stringify(data.responseCode));
              // data.header为HTTP响应头，可根据业务需要进行解析
              console.error('header:' + JSON.stringify(data.header));
              console.error('cookies:' + JSON.stringify(data.cookies)); //

              console.log("test:上传结束")

              httpRequest.destroy()
              this.exout.data = responseString
              resolve(this.exout)
            } else {
              console.error('error:' + JSON.stringify(err));
              // 取消订阅HTTP响应头事件
              httpRequest.off('headersReceive');
              // 当该请求使用完毕时，调用destroy方法主动销毁
              httpRequest.destroy();
              reject()
            }

          }

          )
        }catch (err){
          console.error(err)
        }
      })



  }

}