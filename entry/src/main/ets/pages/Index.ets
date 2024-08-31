// import { BusinessError } from '@ohos.base';
import { rcp } from '@kit.RemoteCommunicationKit';
import { picker } from '@kit.CoreFileKit';
import fs from '@ohos.file.fs';
import { http } from '@kit.NetworkKit';
import { Button, display } from '@kit.ArkUI'
import { RequestAI,DetectionResponse} from '../Utils/requestAI'
import { BusinessError } from '@kit.BasicServicesKit';
import { Permissions } from '@kit.AbilityKit';
import PermissionsUtil from '../Utils/PermissionsUtil';
import { image } from '@kit.ImageKit';
import { resourceManager } from '@kit.LocalizationKit';
import { photoAccessHelper } from '@kit.MediaLibraryKit';

let uploadUrl: string = 'http://192.xx.xxx.xx:8080/upload';
let appCode : string = 'xxx'

// function example01(): string {
//   let uri = '';
//   let photoViewPicker = new picker.PhotoViewPicker();
//   let photoSelectOption = new picker.PhotoSelectOptions();
//   photoSelectOption.MIMEType = picker.PhotoViewMIMETypes.IMAGE_TYPE;
//   photoViewPicker.select(photoSelectOption).then((photoSelectResult) => {
//     console.log("photoSelectResult:" + photoSelectResult);
//     uri = photoSelectResult.photoUris[0];
//     console.log("uri:" + uri);
//
//     // // 创建 RequestAI 实例
//     // let requestAI = new RequestAI(uploadUrl, uri, appCode);
//
//     try {
//       let resultPhoto = fs.openSync(uri,fs.OpenMode.READ_ONLY);
//       let resultName = resultPhoto.name;
//       let fileTemp = fs.openSync(getContext().filesDir+resultPhoto.name,fs.OpenMode.READ_WRITE|fs.OpenMode.CREATE);
//       let imageUri = fileTemp.path;
//       fs.copyFileSync(resultPhoto.fd,fileTemp.fd);
//       fs.closeSync(resultPhoto);
//       fs.closeSync(fileTemp);
//       const httpRequest = http.createHttp();
//       httpRequest.request(uploadUrl,{
//         method:http.RequestMethod.POST,
//         header:{ 'Content-Type': 'multipart/form-data', 'Connection':'keep-alive' },
//         expectDataType:http.HttpDataType.ARRAY_BUFFER,
//         multiFormDataList: [ { name:'file',
//           contentType: 'image/jpg',
//           filePath: imageUri,
//           remoteFileName:'file.jpg' },
//         ],
//       },(err,data) => {
//         console.log('test:上传结束')
//         httpRequest.destroy();
//       } )
//     } catch (err) {
//       console.error('fyh:Failed to request the upload. err: ${JSON.stringify(err)}');
//     } }).catch((err:BusinessError) => {
//     console.error('Invoke photoViewPicker.select failed, code is ${err.code}, message is ${err.message}');
//   })
//   return uri;
// }

let responseData : DetectionResponse

async function example02(): Promise<void> {
  //打开相册选择器并设置图片选择特性
  let photoViewPicker = new picker.PhotoViewPicker();
  let photoSelectOption = new picker.PhotoSelectOptions();
  photoSelectOption.MIMEType = picker.PhotoViewMIMETypes.IMAGE_TYPE;

  try {
    let photoSelectResult = await photoViewPicker.select(photoSelectOption);
    let uri = photoSelectResult.photoUris[0];
    console.log("Selected URI:" + uri);

    // 创建requestAI实例
    let requestAIInstance = new RequestAI(uri);
    // 上传并获取响应数据
    let responseArray = await requestAIInstance.PostAI();
        console.log("服务器返回的数据:", responseArray);

  } catch (err) {
    if ((err as BusinessError).code !== undefined && (err as BusinessError).message !== undefined) {
      console.error(`操作失败: code: ${(err as BusinessError).code}, message: ${(err as BusinessError).message}`);
    } else {
      console.error("上传或解析过程中出错:", err);
    }
  }
}

//封装测试函数
function testRcpMultiPartUpload() {
  example02();
}

//已经获取到返回的Detection类型数据responseData，尝试标记效果
function testMarkingData() {


}

@Entry
@Component struct Index {
  @State message: string = '点此选择照片';
  @State pixelMap:image.PixelMap  | undefined = undefined
  private settings: RenderingContextSettings = new RenderingContextSettings(true)
  private context: CanvasRenderingContext2D = new CanvasRenderingContext2D(this.settings)
  private offCanvas: OffscreenCanvas = new OffscreenCanvas(400,600)
  private img: ImageBitmap = new ImageBitmap("/resources/base/media/2.png")
  private permissions: Array<Permissions> = ['ohos.permission.WRITE_IMAGEVIDEO','ohos.permission.READ_IMAGEVIDEO'];
  build() {
    Column(){
      Flex({ direction: FlexDirection.Column, alignItems: ItemAlign.Center }) {
        Canvas(this.context)
          .width('100%')
          .height('100%')
          .backgroundColor('#ffffff')
          .onReady(() => {
            // this.drawImage();
          })
      }
      .height('70%')
      .margin({ top: 50, left: 5, right: 5 })
      .padding({ bottom: 20 });

      Button(this.message, { type: ButtonType.Capsule })
        .fontSize(20)
        .margin({})
        .onClick(() => {
          testRcpMultiPartUpload();
        });
    }.width('100%')
  }

  //显示图片
  private async drawImage() {
    let offContext = this.offCanvas.getContext("2d", this.settings);

    // 获取图片的原始宽高
    const imgWidth = this.img.width;
    const imgHeight = this.img.height;
    // 计算自适应的宽高
    let drawWidth = 400;
    let drawHeight = (imgHeight / imgWidth) * drawWidth;

    // 使用drawImage接口将图片画在（0，0）为起点，宽400，高自适应的区域
    offContext.drawImage(this.img, 0, 0, drawWidth, drawHeight);
    // 将离屏绘制的内容画到canvas组件上
    let image = this.offCanvas.transferToImageBitmap();
    this.context.transferFromImageBitmap(image);

    // 绘制标注
    if (responseData) {
      this.drawAnnotations(responseData,imgWidth,imgHeight,drawWidth,drawHeight);
    }
  }
  async aboutToAppear(): Promise<void> {
    PermissionsUtil.checkPermissions(this.permissions)
  }
  //标记信息
  private drawAnnotations(response: DetectionResponse,
    imgWidth:number,imgHeight:number,drawWidth:number,drawHeight:number) {

    // 设置检测框
    this.context.strokeStyle = 'red';
    this.context.lineWidth = 2;
    //计算缩放率
    let ratioX = drawWidth/imgWidth
    let ratioY = drawHeight/imgHeight

    response.detection_boxes.forEach((box: number[], index: number) => {
      let x1 = box[0];
      let y1 = box[1];
      let x2 = box[2];
      let y2 = box[3];

      // 计算实际坐标
      const rectX = x1 * ratioX;
      const rectY = y1 * ratioY;
      const rectWidth = (x2 - x1) * ratioX;
      const rectHeight = (y2 - y1) * ratioY;

      // 绘制矩形框
      this.context.beginPath();
      this.context.rect(rectX, rectY, rectWidth, rectHeight);
      this.context.stroke();

      // 绘制标注文本
      this.context.fillStyle = 'red';
      this.context.font = '12px Arial';
      this.context.fillText(response.detection_classes[index], rectX, rectY);
    });
  }

  // build() {
  //
  //     Column() {
  //       // , justifyContent: FlexAlign.Center
  //       Flex({ direction: FlexDirection.Column, alignItems: ItemAlign.Center}) {
  //         Canvas(this.context)
  //           .width('100%')
  //           .height('100%')
  //           .backgroundColor('#ffffff')
  //           .onReady(() => {
  //             let offContext = this.offCanvas.getContext("2d", this.settings)
  //
  //             // 获取图片的原始宽高
  //             const imgWidth = this.img.width;
  //             const imgHeight = this.img.height;
  //             // 计算自适应的宽高
  //             let drawWidth = 400;
  //             let drawHeight = (imgHeight / imgWidth) * drawWidth;
  //
  //             // 使用drawImage接口将图片画在（0，0）为起点，宽400，高自适应的区域
  //             offContext.drawImage(this.img, 0, 0,drawWidth,drawHeight);
  //             // 将离屏绘制的内容画到canvas组件上
  //             let image = this.offCanvas.transferToImageBitmap();
  //             this.context.transferFromImageBitmap(image);
  //
  //             //图形区域是drawWidth*drawHeight的矩形
  //             //绘制矩形
  //             this.context.beginPath();
  //             this.context.rect(100, 50, 100, 100);
  //             this.context.stroke();
  //             //绘制圆形
  //             this.context.beginPath();
  //             this.context.arc(150, 250, 50, 0, 6.28);
  //             this.context.stroke();
  //             //绘制椭圆
  //             this.context.beginPath();
  //             this.context.ellipse(150, 450, 50, 100, Math.PI * 0.25, Math.PI * 0, Math.PI * 2);
  //             this.context.stroke();
  //           })
  //       }
  //       .height('70%')
  //       .margin({top:50,left:5,right:5})
  //       .padding({bottom:20})
  //
  //       Button(this.message, { type: ButtonType.Capsule })
  //         .fontSize(20)
  //         .margin({})
  //         .onClick(() => {
  //           testRcpMultiPartUpload();
  //         })
  //
  //     }.width('100%')
  //   }
  async packingPixelMap2Jpg(pixelMap: PixelMap): Promise<ArrayBuffer> {
    const imagePackerApi = image.createImagePacker();
    const packOpts: image.PackingOption = { format: "image/jpeg", quality: 98 };
    let imageBuffer: ArrayBuffer = new ArrayBuffer(1);
    try {
      // 图片压缩或重新打包
      imageBuffer = await imagePackerApi.packing(pixelMap, packOpts);
    } catch (err) {
      console.error(`Invoke packingPixelMap2Jpg failed, err: ${JSON.stringify(err)}`);
    }
    return imageBuffer;
  }
  async getPixelMapByImage():Promise<image.PixelMap>{
    const context : Context = getContext(this);
    // 获取resourceManager资源管理器
    const resourceMgr : resourceManager.ResourceManager = context.resourceManager;
    let rawFileDescriptor = await resourceMgr.getRawFd('food.png')
    const imageSource : image.ImageSource = image.createImageSource(rawFileDescriptor);
    let decodingOptions : image.DecodingOptions = {
      editable: true,
      desiredPixelFormat: 3,
    }
    // 创建pixelMap并进行简单的旋转和缩放
    const pixelMap:image.PixelMap = await imageSource.createPixelMap(decodingOptions)
    this.pixelMap =  pixelMap
    return pixelMap;
  }
  async  WritePhoto() {
    console.info('createAssetDemo');
    let context = getContext(this);
    let phAccessHelper = photoAccessHelper.getPhotoAccessHelper(context);
    let photoType: photoAccessHelper.PhotoType = photoAccessHelper.PhotoType.IMAGE;
    let extension:string = 'png';
    let options: photoAccessHelper.CreateOptions = {
      title: 'testPhoto'
    }
    let uri = await phAccessHelper.createAsset(photoType, extension, options);
    // 使用uri打开文件，可以持续写入内容，写入过程不受时间限制
    let file = await fs.open(uri, fs.OpenMode.READ_WRITE | fs.OpenMode.CREATE);
    try {
      const imageBuffer = await this.packingPixelMap2Jpg(this.pixelMap as image.PixelMap)

      // 写到媒体库文件中
      await fs.write(file.fd, imageBuffer);
      await fs.close(file.fd);
      AlertDialog.show({message:'已保存至相册!'});
    }
    catch (err) {
      console.error("error is "+ JSON.stringify(err))
    }
  }
}
