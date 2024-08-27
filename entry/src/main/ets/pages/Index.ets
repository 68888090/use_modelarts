import { BusinessError } from '@ohos.base';
import { rcp } from '@kit.RemoteCommunicationKit';
import { picker } from '@kit.CoreFileKit';
import fs from '@ohos.file.fs';
import { http } from '@kit.NetworkKit';
import { Button, display } from '@kit.ArkUI'

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
  @State message: string = '点此选择照片';
  private settings: RenderingContextSettings = new RenderingContextSettings(true)
  private context: CanvasRenderingContext2D = new CanvasRenderingContext2D(this.settings)
  private offCanvas: OffscreenCanvas = new OffscreenCanvas(600,600)
  private img: ImageBitmap = new ImageBitmap("/resources/base/media/2.png")

  build() {

      Column() {
        // , justifyContent: FlexAlign.Center
        Flex({ direction: FlexDirection.Column, alignItems: ItemAlign.Center}) {
          Canvas(this.context)
            .width('100%')
            .height('100%')
            .backgroundColor('#ffffff')
            .onReady(() => {
              let offContext = this.offCanvas.getContext("2d", this.settings)

              // //获取当前屏幕的宽高
              // const windowWidth = display.getDefaultDisplaySync().width
              // const windowHeight = display.getDefaultDisplaySync().height
              // // 获取图片的原始宽高
              // const imgWidth = this.img.width;
              // const imgHeight = this.img.height;
              // // 计算自适应的宽高
              // let drawWidth = windowWidth;
              // let drawHeight = (imgHeight / imgWidth) * windowWidth;
              //
              // if (drawHeight > windowHeight) {
              //   drawHeight = windowHeight;
              //   drawWidth = (imgWidth / imgHeight) * windowHeight;
              // }
              // this.offCanvas.width = drawWidth;
              // this.offCanvas.height = drawHeight;
              //
              // // 在离屏Canvas上绘制自适应的图片
              // offContext.drawImage(this.img, 0, 0, drawWidth, drawHeight);
              // let image = this.offCanvas.transferToImageBitmap();
              // this.context.clearRect(0, 0, drawWidth, drawHeight);
              // this.context.drawImage(image, 0, 0,drawWidth, drawHeight)

              // 使用drawImage接口将图片画在（0，0）为起点，宽高130的区域
              offContext.drawImage(this.img, 0, 0,400,400);
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
        .height('70%')
        .margin({top:50,left:5,right:5})
        .padding({bottom:20})

        // Text(this.message).fontSize(50).fontWeight(FontWeight.Bold)
        //   .onClick(() => {
        //     testRcpMultiPartUpload();
        //   })

        Button(this.message, { type: ButtonType.Capsule })
          .fontSize(20)
          .margin({})
          .onClick(() => {
            testRcpMultiPartUpload();
          })

      }.width('100%')
    }
}
