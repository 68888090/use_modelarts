import { BusinessError } from '@ohos.base';
import { rcp } from '@kit.RemoteCommunicationKit';
import { picker } from '@kit.CoreFileKit';
import fs from '@ohos.file.fs';
import { http } from '@kit.NetworkKit';
let uploadUrl: string = 'http://192.xx.xxx.xx:8080/upload';
function example01(): string {
  let uri = '';
  let photoViewPicker = new picker.PhotoViewPicker();
  let photoSelectOption = new picker.PhotoSelectOptions();
  photoSelectOption.MIMEType = picker.PhotoViewMIMETypes.IMAGE_TYPE;
  photoViewPicker.select(photoSelectOption).then((photoSelectResult) => {
    console.log("photoSelectResult:" + photoSelectResult);
    uri = photoSelectResult.photoUris[0];
    console.log("uri:" + uri);
    try {
      let resultPhoto = fs.openSync(uri,fs.OpenMode.READ_ONLY);
      let resultName = resultPhoto.name;
      let fileTemp = fs.openSync(getContext().filesDir+resultPhoto.name,fs.OpenMode.READ_WRITE|fs.OpenMode.CREATE);
      let imageUri = fileTemp.path;
      fs.copyFileSync(resultPhoto.fd,fileTemp.fd);
      fs.closeSync(resultPhoto);
      fs.closeSync(fileTemp);
      const httpRequest = http.createHttp();
      httpRequest.request(uploadUrl,{
        method:http.RequestMethod.POST,
        header:{ 'Content-Type': 'multipart/form-data', 'Connection':'keep-alive' },
        expectDataType:http.HttpDataType.ARRAY_BUFFER,
        multiFormDataList: [ { name:'file',
          contentType: 'image/jpg',
          filePath: imageUri,
          remoteFileName:'file.jpg' },
        ],
      },(err,data) => {
        console.log('test:上传结束')
        httpRequest.destroy();
      } )
    } catch (err) {
      console.error('fyh:Failed to request the upload. err: ${JSON.stringify(err)}');
    } }).catch((err:BusinessError) => {
    console.error('Invoke photoViewPicker.select failed, code is ${err.code}, message is ${err.message}');
  })
  return uri;
}
function testRcpMultiPartUpload() {
  example01();
}

@Entry
@Component struct Index {
  @State message: string = '按此选择照片';
  private settings: RenderingContextSettings = new RenderingContextSettings(true)
  private context: CanvasRenderingContext2D = new CanvasRenderingContext2D(this.settings)
  private offCanvas: OffscreenCanvas = new OffscreenCanvas(600, 600)
  private img: ImageBitmap = new ImageBitmap("/resources/base/media/2.png")

  build() {

      Column() {

        Text(this.message).fontSize(50).fontWeight(FontWeight.Bold)
          .onClick(() => {
            testRcpMultiPartUpload();
          })




        Flex({ direction: FlexDirection.Column, alignItems: ItemAlign.Center, justifyContent: FlexAlign.Center }) {
          Canvas(this.context)
            .width('100%')
            .height('100%')
            .backgroundColor('#ffffff')
            .onReady(() => {
              let offContext = this.offCanvas.getContext("2d", this.settings)
              // 使用drawImage接口将图片画在（0，0）为起点，宽高130的区域
              offContext.drawImage(this.img, 0, 0);
              // 使用getImageData接口，获得canvas组件区域中，（50，50）为起点，宽高130范围内的绘制内容
              let imagedata = offContext.getImageData(50, 50, 130, 130);
              // 使用putImageData接口将得到的ImageData画在起点为（150， 150）的区域中
              //offContext.putImageData(imagedata, 150, 150);
              // 将离屏绘制的内容画到canvas组件上
              let image = this.offCanvas.transferToImageBitmap();
              this.context.transferFromImageBitmap(image);


              //绘制矩形
              this.context.beginPath();
              this.context.rect(100, 50, 100, 100);
              this.context.stroke();
              //绘制圆形
              this.context.beginPath();
              this.context.arc(150, 250, 50, 0, 6.28);
              this.context.stroke();
              //绘制椭圆
              this.context.beginPath();
              this.context.ellipse(150, 450, 50, 100, Math.PI * 0.25, Math.PI * 0, Math.PI * 2);
              this.context.stroke();
            })
        }

      }.width('100%')

  }
}
