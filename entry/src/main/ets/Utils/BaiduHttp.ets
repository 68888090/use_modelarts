import { http } from '@kit.NetworkKit';
import { BusinessError, UploadResponse } from '@kit.BasicServicesKit';
import { promptAction } from '@kit.ArkUI';

export interface ChatResponse{
  result:string
}
export let responseString : string

class HttpUtils{
  static chatUrl:string='https://aip.baidubce.com/rpc/2.0/ai_custom/v1/wenxinworkshop/chat/completions_pro?access_token=';
  static access_token:string='24.a884f4b5f161d01456c6788473c8b7f0.2592000.1728384324.282335-115507853';
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
                  "content": question
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

  requestVoice(){}
}

export default new BaiduHttp;