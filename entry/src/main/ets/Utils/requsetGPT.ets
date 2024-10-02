import { http } from '@kit.NetworkKit';
import { BusinessError, UploadResponse } from '@kit.BasicServicesKit';
import fs from '@ohos.file.fs';
import request from '@ohos.request';
import promptAction from '@ohos.promptAction';
import * as PriData from './Pri_data';

class Utils{
  static chatUrl:string='https://aip.baidubce.com/rpc/2.0/ai_custom/v1/wenxinworkshop/chat/completions_pro?access_token=';
  static access_token:string='24.a884f4b5f161d01456c6788473c8b7f0.2592000.1728384324.282335-115507853';
  static api_key = 'DLjV2q0MNIqlFBbAbmGcB19G';
  static secret_key = '30EB7bqhBn3xFj3tyMQa3iQNyxxVXPgV'
}

class RequestGPT {

  url:string ='https://aip.baidubce.com/oauth/2.0/token'
  api_key:string = ''
  secret_key:string = ''
  grant_type = 'grant_type=client_credentials'
  client_id = 'client_id'
  client_secret = 'client_secret'
  address = ''
  responseString = ''
  responseStrings= '';

  constructor (api_key:string ,secret_key:string) {
    this.address = this.url+'?'+this.grant_type+'&'+this.client_id+'='+api_key+this.client_secret+'='+secret_key
    this.api_key = api_key
    this.secret_key = secret_key
    const context = getContext(this)

  }

  private  post_token():Promise<string>{
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
          this.address,
          {
            method:http.RequestMethod.POST,
            header:{
              'Content-Type':'application/json',
              'Accept':'application/json'
            },
            expectDataType:http.HttpDataType.STRING,
          },(err:BusinessError,data:http.HttpResponse)=>{
          if(!err){
            promptAction.showToast({
              message: '数据传输成功'//弹窗内容
            })
            // data.result为HTTP响应内容，可根据业务需要进行解析
            this.responseString = data.result.toString()
            console.error('Result:' + this.responseString);
            console.error('code:' + JSON.stringify(data.responseCode));
            // data.header为HTTP响应头，可根据业务需要进行解析
            console.error('header:' + JSON.stringify(data.header));
            console.error('cookies:' + JSON.stringify(data.cookies));

            console.log("test:上传结束")

            httpRequest.destroy()

            resolve(this.responseString)
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

  postGPT(data:string):Promise<string>{
    return new Promise(async (resolve,reject)=>{
      try{
        let httpRequest = http.createHttp()
        httpRequest.on('headersReceive', (header) => {
          console.info('header: ' + JSON.stringify(header));
        });
        promptAction.showToast({
          message: '数据传输中！'//弹窗内容
        })

        let uir = 'https://aip.baidubce.com/rpc/2.0/ai_custom/v1/wenxinworkshop/chat/completions_pro?access_token='
        let temp = await this.post_token().then((value:string)=>{
          uir = uir+value
        }).catch((error: Error) => {
          console.error('can not get token '+error)
        })

        httpRequest.request(
          uir,
          {
            method:http.RequestMethod.POST,
            header:{
              'Content-Type':'application/json'
            },
              expectDataType:http.HttpDataType.STRING,
            multiFormDataList: [ // 可选，仅当Header中，'content-Type'为'multipart/form-data'时生效，自API 11开始支持该属性
              {
                name: "Part1", // 数据名，自API 11开始支持该属性
                contentType: 'application/json', // 数据类型，自API 11开始支持该属性
                data: 'message:[' +
                  '{' +
                  'role : user' +
                  'content'+ data+
                  '}' +
                  ']', // 可选，数据内容，自API 11开始支持该属性
                remoteFileName: 'send.txt' // 可选，自API 11开始支持该属性
              }],
          },(err:BusinessError,data:http.HttpResponse)=>{
          if(!err){
            promptAction.showToast({
              message: '数据传输成功'//弹窗内容
            })
            // data.result为HTTP响应内容，可根据业务需要进行解析
            this.responseStrings = data.result.toString()
            console.error('Result:' + this.responseString);
            console.error('code:' + JSON.stringify(data.responseCode));
            // data.header为HTTP响应头，可根据业务需要进行解析
            console.error('header:' + JSON.stringify(data.header));
            console.error('cookies:' + JSON.stringify(data.cookies)); //

            console.log("test:上传结束")

            httpRequest.destroy()
            // let result = JSON.parse(this.responseStrings) as JSON
            resolve(this.responseStrings)
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

export default new RequestGPT(Utils.api_key,Utils.secret_key);