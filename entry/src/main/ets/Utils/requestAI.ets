import { http } from '@kit.NetworkKit';
import { BusinessError, UploadResponse } from '@kit.BasicServicesKit';
import fs from '@ohos.file.fs';
import request from '@ohos.request';


class RequestAI {

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
   async  PostAI() {
    let uploader = await request.uploadFile(getContext(),{
      method:'POST',
      url:this.url,
      header:{
        'Content-Type':'multipart/form-data',
        'X-Apig-AppCode':this.appCode
      },
      files:[{filename:this.fileName,type:'jpg',name:'img',uri:this.copyFilePath}],
      data:[]
    }).then(res=>{
      res.on('progress',(uploaderSize,totalSize)=>{
        if(uploaderSize==totalSize){
          AlertDialog.show({message:"上传成功"})
        }
      })
      res.on('headerReceive',(value)=>{
        let uploadRes = (value as UploadResponse)
        let response = JSON.parse(uploadRes.data) as Array<number>
      })
    })

  }
}