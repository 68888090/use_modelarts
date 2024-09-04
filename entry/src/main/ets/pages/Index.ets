// import { BusinessError } from '@ohos.base';
import { rcp } from '@kit.RemoteCommunicationKit';
import { picker } from '@kit.CoreFileKit';
import fs from '@ohos.file.fs';
import { http } from '@kit.NetworkKit';
import { Button, display, promptAction } from '@kit.ArkUI'
import { RequestAI, DetectionResponse } from '../Utils/requestAI'
import { BusinessError } from '@kit.BasicServicesKit';
import { Permissions } from '@kit.AbilityKit';
import PermissionsUtil from '../Utils/PermissionsUtil';
import { image } from '@kit.ImageKit';
import { resourceManager } from '@kit.LocalizationKit';
import { photoAccessHelper } from '@kit.MediaLibraryKit';
import { responseString } from '../Utils/requestAI'
import { GG } from '../Utils/Pri_data';
import { media } from '@kit.MediaKit';

let responseStr: string = ""
let responseData: DetectionResponse | null = null
let photoUri: string = ""
// 获取图片的原始宽高
let imgWidth = 500;
let imgHeight = 500;

async function getImageUri():Promise<void>{
  //打开相册选择器并设置图片选择特性
  let photoViewPicker = new picker.PhotoViewPicker();
  let photoSelectOption = new picker.PhotoSelectOptions();
  photoSelectOption.MIMEType = picker.PhotoViewMIMETypes.IMAGE_TYPE;
  try {
    let photoSelectResult = await photoViewPicker.select(photoSelectOption);
    let uri = photoSelectResult.photoUris[0];
    photoUri = uri
    console.log("Selected URI:" + uri);

    //在获得原始像素值之前，获得当前图片长宽比
    let img :ImageBitmap = new ImageBitmap(uri)
    imgWidth = img.width
    imgHeight = img.height
  }catch (err) {
      console.error("图片选择过程中出错:", err);
  }
}

async function example02(): Promise<void> {

  try {
    let uri = photoUri

    // 创建requestAI实例
    let requestAIInstance = new RequestAI(uri);
    // 上传并获取响应数据
    await requestAIInstance.PostAI().then((response: GG) => {
      responseStr = response.data
      imgWidth = response.width
      imgHeight = response.height
    }).catch((error: Error) => {
      console.error('Error communicating with AI')
    })

    console.log("服务器返回的数据:", responseStr);

    //0010 Respoonse
    responseStr = "{\"detection_classes\": [\"Mouse_bite\", \"Mouse_bite\", \"Mouse_bite\", \"Open_circuit\", \"Mouse_bite\", \"Open_circuit\", \"Mouse_bite\", \"Open_circuit\", \"Mouse_bite\", \"Open_circuit\"], \"detection_boxes\": [[578, 646, 604, 672], [559, 609, 584, 640], [407, 264, 424, 303], [1052, 912, 1075, 925], [26, 740, 38, 761], [715, 1351, 743, 1358], [62, 1382, 84, 1397], [714, 1050, 724, 1074], [68, 864, 78, 884], [823, 1099, 834, 1108]], \"detection_scores\": [0.954258, 0.93341, 0.933286, 0.930765, 0.919465, 0.918447, 0.917989, 0.913556, 0.910603, 0.886787]}\n"

    //解析服务器返回的数据为DetectionResponse
    try {
      responseData = JSON.parse(responseStr) as DetectionResponse;
      console.error("解析后的数据:", responseData.detection_classes[0]);
    } catch (error) {
      console.error("解析服务器返回的数据时出错:", error);
    }

  } catch (err) {
    if ((err as BusinessError).code !== undefined && (err as BusinessError).message !== undefined) {
      console.error(`操作失败: code: ${(err as BusinessError).code}, message: ${(err as BusinessError).message}`);
    } else {
      console.error("上传或解析过程中出错:", err);
    }
  }
}

let displayer =  display.getDefaultDisplaySync()


@Entry
@Component
struct Index {
  @State message: string = '点此选择照片';
  @State pixelMap: image.PixelMap | undefined = undefined
  private settings: RenderingContextSettings = new RenderingContextSettings(true)
  private context: CanvasRenderingContext2D = new CanvasRenderingContext2D(this.settings)
  private offCanvas: OffscreenCanvas = new OffscreenCanvas(375, 600)
  private img: ImageBitmap | null = null
  private permissions: Array<Permissions> = ['ohos.permission.WRITE_IMAGEVIDEO', 'ohos.permission.READ_IMAGEVIDEO'];
  @State scaleValue: number = 1
  @State pinchValue: number = 1
  @State pinchX: number = 0
  @State pinchY: number = 0

  build() {
    Column() {
      Flex({ direction: FlexDirection.Column, alignItems: ItemAlign.Center }) {
        Canvas(this.context)
          .width('100%')
          .height('100%')
          .backgroundColor('#ffffff')
          .scale({ x: this.scaleValue, y: this.scaleValue, z: 1 })
          .onReady(() => {
            // this.drawImage();
          })
          .gesture(PinchGesture({ fingers: 2 })

            .onActionStart((event: GestureEvent) => {
              console.info('Pinch start')
            })
            .onActionUpdate((event: GestureEvent) => {
              if (event) {
                this.scaleValue = this.pinchValue * event.scale
                this.pinchX = event.pinchCenterX
                this.pinchY = event.pinchCenterY
              }
            })
            .onActionEnd((event: GestureEvent) => {
              this.pinchValue = this.scaleValue
              console.info('Pinch end')
            })
          )
      }
      .backgroundColor('red')
      .height('60%')
      .margin({
        top: 100,
        bottom: 10,
        left: 5,
        right: 5
      });

      Button(this.message, { type: ButtonType.Capsule })
        .fontSize(20)
        .margin({})
        .onClick(() => {
          if (this.context) {
            this.context.clearRect(0, 0, this.context.width, this.context.height);

          }
          this.uploadAndDrawImage();
        });
      Image($r('app.media.1'))
        .height('30%')

    }.width('100%')


  }

  // 延迟触发绘图
  async uploadAndDrawImage() {
    await getImageUri();

    if (photoUri) { // 假设 photoUri 是图片的 URI
      this.img = new ImageBitmap(photoUri)
      if (await this.drawImage()) {
        await example02();
        if (responseData) { // 绘制标注
          this.drawAnnotations(responseData, imgWidth, 370);
        } else {
          promptAction.showToast({
            message: '没有可用的DetectResponse类型数据'
          })
        }
      }
    } else {
      console.error('不存在有效的图片地址')
    }
  }

  //显示图片
  public  async  drawImage(): Promise<boolean> {
    if (this.img) {
      let offContext = this.offCanvas.getContext("2d", this.settings);
      offContext.clearRect(0,0,375,600)

      // 计算自适应的宽高
      let drawWidth = 375;
      let drawHeight = (imgHeight / imgWidth) * drawWidth;

      // 使用drawImage接口将图片画在（0，0）为起点，宽400，高自适应的区域
      offContext.drawImage(this.img, 0, 0, drawWidth, drawHeight);
      // 将离屏绘制的内容画到canvas组件上
      let image = this.offCanvas.transferToImageBitmap();
      this.context.transferFromImageBitmap(image);
      return true
    } else {
      promptAction.showToast({
        message: '创建图片实例ImageBitmap未成功'
      })
      return false
    }
  }

  async aboutToAppear(): Promise<void> {
    PermissionsUtil.checkPermissions(this.permissions)
  }

  //标记信息
  private drawAnnotations(response: DetectionResponse,
    imgWidth: number, drawWidth: number) {

    // 设置检测框
    // this.context.strokeStyle = 'green';
    this.context.lineWidth = 1;
    //计算缩放率
    let ratio = drawWidth / imgWidth

    response.detection_boxes.forEach((box: number[], index: number) => {

      let y1 = box[0];
      let x1 = box[1];
      let y2 = box[2];
      let x2 = box[3];

      // 计算实际坐标
      let rectX = x1 * ratio;
      let rectY = y1 * ratio;
      let rectWidth = (x2 - x1) * ratio;
      let rectHeight = (y2 - y1) * ratio;
      let x21 = x2 * ratio
      let y21 = y2 * ratio

      // 绘制矩形框
      this.context.beginPath();
      this.context.rect(rectX, rectY, rectWidth, rectHeight);
      this.context.stroke();

      if(response.detection_classes[index]=="Open_circuit"){
        this.context.strokeStyle = '001B1B';
      }else if(response.detection_classes[index]=="Mouse_bite"){
        this.context.strokeStyle = 'green';
      }else{
        this.context.strokeStyle = 'red';
      }

      this.context.fillStyle = 'white';
      this.context.font = '40px Arial';
      this.context.shadowColor = 'black';

      // this.context.fillText(response.detection_classes[index] + "(" +
      // (response.detection_scores[index] * 100).toFixed(0) + "%)",
      //   rectX-40, y21+10);

      this.context.fillText( "(" + (response.detection_scores[index] * 100).toFixed(0) + "%)",
        x21+5, y21+2);
    });
  }

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

//   async  example02(): Promise<void> {
//   //打开相册选择器并设置图片选择特性
//   let photoViewPicker = new picker.PhotoViewPicker();
//   let photoSelectOption = new picker.PhotoSelectOptions();
//   photoSelectOption.MIMEType = picker.PhotoViewMIMETypes.IMAGE_TYPE;
//
//   try {
//     let photoSelectResult = await photoViewPicker.select(photoSelectOption);
//     let uri = photoSelectResult.photoUris[0];
//     photoUri = uri
//     console.log("Selected URI:" + uri);
//     //每次绘制图片前先清空画布
//
//
//     // getImageSize(uri)
//     // 创建requestAI实例
//     let requestAIInstance = new RequestAI(uri);
//     // 上传并获取响应数据
//     await requestAIInstance.PostAI().then((response: GG) => {
//       responseStr = response.data
//       imgWidth = response.width
//       imgHeight = response.height
//     }).catch((error: Error) => {
//       console.error('Error communicating with AI')
//     })
//
//
//     console.log("服务器返回的数据:", responseStr);
//     //将PostAI返回的字符串数据赋值给当前文件中的全局变量responseStr
//     // responseStr = responseArray
//     // responseStr = "{\"detection_classes\": [\"Mouse_bite\", \"Mouse_bite\", \"Mouse_bite\", \"Open_circuit\", \"Mouse_bite\", \"Open_circuit\", \"Mouse_bite\", \"Open_circuit\", \"Mouse_bite\", \"Open_circuit\"], \"detection_boxes\": [[578, 646, 604, 672], [559, 609, 584, 640], [407, 264, 424, 303], [1052, 912, 1075, 925], [26, 740, 38, 761], [715, 1351, 743, 1358], [62, 1382, 84, 1397], [714, 1050, 724, 1074], [68, 864, 78, 884], [823, 1099, 834, 1108]], \"detection_scores\": [0.954258, 0.93341, 0.933286, 0.930765, 0.919465, 0.918447, 0.917989, 0.913556, 0.910603, 0.886787]}"
//
//     //解析服务器返回的数据为DetectionResponse
//     try {
//       responseData = JSON.parse(responseStr) as DetectionResponse;
//       console.error("解析后的数据:", responseData.detection_classes[0]);
//     } catch (error) {
//       console.error("解析服务器返回的数据时出错:", error);
//     }
//
//   } catch (err) {
//     if ((err as BusinessError).code !== undefined && (err as BusinessError).message !== undefined) {
//       console.error(`操作失败: code: ${(err as BusinessError).code}, message: ${(err as BusinessError).message}`);
//     } else {
//       console.error("上传或解析过程中出错:", err);
//     }
//   }
// }

}

