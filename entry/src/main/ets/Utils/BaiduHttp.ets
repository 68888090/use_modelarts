import { http } from '@kit.NetworkKit';
import { BusinessError, UploadResponse } from '@kit.BasicServicesKit';
import { promptAction } from '@kit.ArkUI';
import fileio from '@ohos.fileio';
import fs from '@ohos.file.fs';
import util from '@ohos.util';
import common from '@ohos.app.ability.common';
import { buffer } from '@kit.ArkTS';

export interface ChatResponse{
  result:string
}
export let responseString : string

class HttpUtils{
  static chatUrl:string='https://aip.baidubce.com/rpc/2.0/ai_custom/v1/wenxinworkshop/chat/completions_pro?access_token=';
  static access_token:string='24.a884f4b5f161d01456c6788473c8b7f0.2592000.1728384324.282335-115507853';
  static voiceUrl:string = 'https://vop.baidu.com/server_api';
  static access_token1:string = '25.50d9d591cbbf591869fe243fe3d29fbe.315360000.2042961219.282335-115738104';
  static access_token2:string = '24.cabad1967ccd5d11f3275835960be382.2592000.1730192869.282335-115738532';
}

class yuyinclass{
  err_msg:string = ''
  err_no:number = 1234
    sn:string=''
}

class BaiduHttp{
  requestChat(question:string, callback: Function):Promise<void>{
    return new Promise((resolve,reject)=>{
      const  url:string = HttpUtils.chatUrl
      const  access_token:string =HttpUtils.access_token

      try{
        let httpRequest = http.createHttp()
        httpRequest.on('headersReceive', (header) => {
          console.info('header: ' + JSON.stringify(header));
        });
        httpRequest.request(
          url+access_token,
          {
            method:http.RequestMethod.POST,
            header:{
              'Content-Type':'application/json'
            },
            extraData: {
              "messages": [
                {
                  "role": "user",
                  "content": question+'\n回答的简单一点。'
                }
              ]
            },
          },(err:BusinessError,data:http.HttpResponse)=>{
          if(!err){
            console.error( '数据传输成功')
            //获取返回的result
            responseString = data.result.toString()
            console.error('Result:' + responseString);
            console.error('code:' + JSON.stringify(data.responseCode));
            console.error('header:' + JSON.stringify(data.header));
            console.error('cookies:' + JSON.stringify(data.cookies));

            let response: ChatResponse|null = null
            try {
              response = JSON.parse(responseString) as ChatResponse
            }catch (e){
              console.error("解析服务器返回数据为ChatResponse类型时出错:", e);
            }

            console.error("test:上传结束")
            httpRequest.destroy()
            if(response){
              callback(response.result)
            }else{
              console.error("解析服务器返回数据结果为null");
            }
          } else {
            console.error('error:' + JSON.stringify(err));
            // 取消订阅HTTP响应头事件
            httpRequest.off('headersReceive');
            // 当该请求使用完毕时，调用destroy方法主动销毁
            httpRequest.destroy();
            reject()
          }
        })
      }catch (err){
        console.error(err)
      }
    })
	}

  requestPhoto(){}
   filepath= ''
  requestVoice(filepath:string, callback: Function):Promise<void>{
    return new Promise((resolve,reject)=>{

      this.filepath= filepath
      this.copyPath()
    const  url:string = HttpUtils.voiceUrl
    const  access_token:string =HttpUtils.access_token1
      filepath = this.imageuri
      console.error('filePath         :' + filepath) // 打印地址
      let  stat:fs.Stat// 获取文件状态
      try{


      console.error(`第一次:${0 - new Date().getTime()}`)
      let file = fs.openSync(filepath, fs.OpenMode.READ_WRITE); // 打开文件
        stat = fs.statSync(filepath);
        console.error("stat.size:"+stat.size) // 打印文件的长度
      let buf = new ArrayBuffer(stat.size); // 创建一个ArrayBuffer对象
      let base64 = new  util.Base64Helper(); // 实例化Base64Helper
      let num = fs.readSync(file.fd, buf);   // 读取文件
      let data1 = buffer.from(buf,0,num)
      let data2 = data1.toString('base64')
      // let data = base64.encodeSync(new Uint8Array(buf.slice(0, num))) //  转换成Uint8Array

      // let textDecoder = util.TextDecoder.create('utf-8', { ignoreBOM : true })
      // let retStr = textDecoder.decodeWithStream( data , {stream: false})   // 可以把Uint8Array转码成base64
      // console.log('dsadfas')
      // console.error(retStr)  // 打印结果
      fs.close(file)
      // file = fs.openSync('C:\\Users\\luyu\\Pictures\\gif图库\\16k.pcm')
      // stat = fs.statSync(file.path)
      // console.error(`data长度:${data.length}`)
      // console.error(`data:${data}`)
      console.error(`data2长度:${data2.length}`)
      console.error(`data2:${data2}`)
    try{
      let httpRequest = http.createHttp()
      httpRequest.on('headersReceive', (header) => {
        console.info('header: ' + JSON.stringify(header));
      });
      httpRequest.request(
        url,
        {
          method:http.RequestMethod.POST,
          header:{
            'Content-Type':'application/json',
            'Accept':'application/json'
          },
          // expectDataType:http.HttpDataType.STRING,
          extraData: {
            'format':'pcm',
            'rate':16000,
            'dev_pid':1537,
            'channel':1,
            'token':HttpUtils.access_token2,
            'cuid':'3E-C0-13-BA-59-73',
            'len':stat.size,
            'speech':data2
          },

        },(err:BusinessError,data:http.HttpResponse)=>{
        if(!err){
          console.error( '数据传输成功')
          //获取返回的result
          responseString = data.result.toString()
          let temp = JSON.parse(responseString) as yuyinclass
          if(temp.err_no!=0&&temp.err_msg!='success'){
            promptAction.showToast({
              message: '识别失败!'//弹窗内容
            })
          }
          console.error('Result:' + responseString);
          console.error('code:' + JSON.stringify(data.responseCode));
          console.error('header:' + JSON.stringify(data.header));
          console.error('cookies:' + JSON.stringify(data.cookies));

          let response: ChatResponse|null = null
          try {
            response = JSON.parse(responseString) as ChatResponse
          }catch (e){
            console.error("解析服务器返回数据为ChatResponse类型时出错:", e);
          }

          console.error("test:上传结束")
          httpRequest.destroy()
          if(response){
            callback(response.result)
            resolve()
          }else{
            console.error("解析服务器返回数据结果为null");
          }
        } else {
          console.error('error:' + JSON.stringify(err));
          // 取消订阅HTTP响应头事件
          httpRequest.off('headersReceive');
          // 当该请求使用完毕时，调用destroy方法主动销毁
          httpRequest.destroy();
          reject()
        }
      })

    }catch(e){
        console.error(e)
    }
    }catch (err){
      console.error(err)
    }
  })}
 imageuri=''
   copyPath(){


     const context = getContext(this)
     const fileType = 'pcm'
     // （以时间戳）生成一个新的文件名
     let fileName = Date.now() + '.' + fileType
     // 通过缓存路径+文件名 拼接出完整的路径
     let copyFilePath = context.cacheDir + '/' + fileName
     console.error('copyfilepath'+copyFilePath)
     // 将文件 拷贝到 临时目录

     // let temp = this.filepath
     let temp =        "file://docs/storage/Users/currentUser/Download/16.pcm"
     const file = fs.openSync(temp, fs.OpenMode.READ_ONLY)
      console.error(file.name)

     let fileTemp = fs.openSync(getContext().filesDir+'/'+fileName,fs.OpenMode.READ_WRITE|fs.OpenMode.CREATE);
     this.imageuri  = fileTemp.path
     // this.imageuri  = fileTemp.path
     // PriData.getImageSize(fileTemp.path).then((temp:PriData.GeneratedTypeLiteralInterface_1)=>{
     //   this.exout.width = temp.width
     //   this.exout.height = temp.height
     // })
     console.error('filePath '+this.filepath);
     console.error('filePathtemp '+fileTemp.path);



     fs.copyFileSync(file.fd, fileTemp.fd)
     fs.closeSync(file)
     fs.closeSync(fileTemp)
   }
}

export default new BaiduHttp;