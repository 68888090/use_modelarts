// import { BusinessError } from '@ohos.base';
import { rcp } from '@kit.RemoteCommunicationKit';
import { picker } from '@kit.CoreFileKit';
import fs from '@ohos.file.fs';
import { http } from '@kit.NetworkKit';
import { Button, display, promptAction } from '@kit.ArkUI'
import { RequestAI,DetectionResponse} from '../Utils/requestAI'
import { BusinessError } from '@kit.BasicServicesKit';
import { Permissions } from '@kit.AbilityKit';
import PermissionsUtil from '../Utils/PermissionsUtil';
import { image } from '@kit.ImageKit';
import { resourceManager } from '@kit.LocalizationKit';
import { photoAccessHelper } from '@kit.MediaLibraryKit';
import { responseString} from '../Utils/requestAI'

let responseStr : string = ""
let responseData : DetectionResponse|null = null
let photoUri : string = ""

async function example02(): Promise<void> {
  //打开相册选择器并设置图片选择特性
  let photoViewPicker = new picker.PhotoViewPicker();
  let photoSelectOption = new picker.PhotoSelectOptions();
  photoSelectOption.MIMEType = picker.PhotoViewMIMETypes.IMAGE_TYPE;

  try {
    let photoSelectResult = await photoViewPicker.select(photoSelectOption);
    let uri = photoSelectResult.photoUris[0];
    photoUri = uri
    console.log("Selected URI:" + uri);

    // 创建requestAI实例
    let requestAIInstance = new RequestAI(uri);
    // 上传并获取响应数据
    let responseArray = await requestAIInstance.PostAI();
        console.log("服务器返回的数据:", responseArray);
        //将PostAI返回的字符串数据赋值给当前文件中的全局变量responseStr
        // responseStr = responseString
    responseStr = "{\"detection_classes\": [\"Mouse_bite\", \"Mouse_bite\", \"Mouse_bite\", \"Open_circuit\", \"Mouse_bite\", \"Open_circuit\", \"Mouse_bite\", \"Open_circuit\", \"Mouse_bite\", \"Open_circuit\"], \"detection_boxes\": [[578, 646, 604, 672], [559, 609, 584, 640], [407, 264, 424, 303], [1052, 912, 1075, 925], [26, 740, 38, 761], [715, 1351, 743, 1358], [62, 1382, 84, 1397], [714, 1050, 724, 1074], [68, 864, 78, 884], [823, 1099, 834, 1108]], \"detection_scores\": [0.954258, 0.93341, 0.933286, 0.930765, 0.919465, 0.918447, 0.917989, 0.913556, 0.910603, 0.886787]}"

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

@Entry
@Component struct Index {
  @State message: string = '点此选择照片';
  @State pixelMap:image.PixelMap  | undefined = undefined
  private settings: RenderingContextSettings = new RenderingContextSettings(true)
  private context: CanvasRenderingContext2D = new CanvasRenderingContext2D(this.settings)
  private offCanvas: OffscreenCanvas = new OffscreenCanvas(400,600)
  private img: ImageBitmap|null = null
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
      .backgroundColor('red')
      .height('60%')
      .margin({ top: 100, bottom: 10, left: 5, right: 5 });

      Button(this.message, { type: ButtonType.Capsule })
        .fontSize(20)
        .margin({})
        .onClick(() => {
          this.uploadAndDrawImage();
        });
    }.width('100%')
  }

  // 延迟触发绘图
  async uploadAndDrawImage() {
    await example02();

    if (photoUri) {  // 假设 photoUri 是图片的 URI

      //每次绘制图片前先清空画布
      if (this.context) {
        this.context.clearRect(0, 0, this.context.width, this.context.height);
      }

      this.img = new ImageBitmap(photoUri)
      await this.drawImage();  // 触发绘图

      if (responseData) {// 绘制标注
        this.drawAnnotations(responseData,1720,400);
      }else{
        promptAction.showToast({
          message: '没有可用的DetectResponse类型数据'
        })
      }
    }else{
      console.error('不存在有效的图片地址')
    }
  }

  //显示图片
  private async drawImage() {
    if(this.img){
      let offContext = this.offCanvas.getContext("2d", this.settings);

      // 获取图片的原始宽高
      let imgWidth = 1720;
      let imgHeight = 1132;
      // 计算自适应的宽高
      let drawWidth = 400;
      let drawHeight = (imgHeight / imgWidth) * drawWidth;

      console.error("自动获取的图片宽高为："+this.img.width+","+this.img.height+",实际为1720，1140")
      //自动获取的图片宽高为：529.2307692307693,348.3076923076923,实际为1720，1140

      // 使用drawImage接口将图片画在（0，0）为起点，宽400，高自适应的区域
      offContext.drawImage(this.img, 0, 0, drawWidth, drawHeight);
      // 将离屏绘制的内容画到canvas组件上
      let image = this.offCanvas.transferToImageBitmap();
      this.context.transferFromImageBitmap(image);

    }else{
      promptAction.showToast({
        message: '创建图片实例ImageBitmap未成功'
      })
    }
  }

  async aboutToAppear(): Promise<void> {
    PermissionsUtil.checkPermissions(this.permissions)
  }

  //标记信息
  private drawAnnotations(response: DetectionResponse,
    imgWidth:number,drawWidth:number) {

    // 设置检测框
    this.context.strokeStyle = 'green';
    this.context.lineWidth = 0.5;
    //计算缩放率
    let ratio = drawWidth/imgWidth

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
      let x21 = x2*ratio
      let y21 = y2*ratio

      // 绘制矩形框
      this.context.beginPath();
      this.context.rect(rectX, rectY, rectWidth, rectHeight);
      this.context.stroke();

      // 绘制标注文本
      this.context.fillStyle = 'white';
      this.context.font = '24px Arial';
      this.context.fillText(response.detection_classes[index]+"("+(response.detection_scores[index]*100).toFixed(0)+"%)",
        rectX, y21+3);
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
