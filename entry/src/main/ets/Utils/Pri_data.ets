import { image } from '@kit.ImageKit';

export  interface GeneratedTypeLiteralInterface_1 {
  width: number;
  height: number;
}

interface GeneratedObjectLiteralInterface_1 {
  width: number;
  height: number;
}

export  async function getImageSize(filePath: string): Promise<GeneratedTypeLiteralInterface_1> {
    return new Promise(async (resolve,reject)=>{
      try {
        // 通过文件路径创建ImageSource
        const imageSource = await image.createImageSource(filePath);
        let imggg=new ImageBitmap(filePath)

        // 设置解码参数，这里使用默认参数或根据需要调整
        const decodingOptions: image.DecodingOptions = {
          editable: true, // 是否可编辑
          desiredPixelFormat: image.PixelMapFormat.RGBA_8888, // 期望的像素格式
          // 可以添加其他解码选项
        };

        // 解码图片以获取PixelMap对象
        const pixelMap = await imageSource.createPixelMap(decodingOptions);

        // 获取图片信息
        const imageInfo = await pixelMap.getImageInfo();
        console.error('Height:'+imageInfo.size.height+' width ' +imageInfo.size.width);
        // 返回图片的宽和高
        let fd: GeneratedObjectLiteralInterface_1 = {
          width: imageInfo.size.width,
          height: imageInfo.size.height,
        };
        resolve(fd)
      } catch (error) {
        console.error('Failed to get image size:', error);
        let fd: GeneratedObjectLiteralInterface_1 = {
          width:0,height:0,
        };
        reject(fd)
      }
    })

}

export interface GG extends GeneratedTypeLiteralInterface_1{
  data:string
}