// For demo only
import 'package:shop/constants.dart';

class ProductModel {
  final String image, brandName, title;
  final String date;
  final double? priceAfetDiscount;
  final int? dicountpercent;

  ProductModel({
    required this.image,
    required this.brandName,
    required this.title,
    required this.date,
    this.priceAfetDiscount,
    this.dicountpercent,
  });
}

List<ProductModel> demoPopularProducts = [
  ProductModel(
    image: productDemoImg1,
    title: "Livelihood Assistance recipients",
    brandName: "Lipsy london",
    date: "12/01/2024",
  
  ),
  ProductModel(
    image: productDemoImg4,
    title: "Mountain Beta Warehouse",
    brandName: "Lipsy london",
    date: "12/01/2024",
  ),
  ProductModel(
    image: productDemoImg5,
    title: "DSWD awards 10 LGUs for Project LAWA at BINHI success stories",
    brandName: "DSWD NEWS",
     date: "12/01/2024",
   
  ),
  ProductModel(
    image: productDemoImg6,
    title: "DSWD gears for full rollout of ready-to-eat food packs",
    brandName: "DSWD NEWS",
    date: "12/01/2024",
  
  ),
  ProductModel(
    image: "https://www.bworldonline.com/wp-content/uploads/2022/10/4Ps-PANTAWIDE.DSWD_.GOV_.PH_.jpg",
    title: "DSWD concludes 2nd National ABSNet Bi-Annual Activity and Conference for 2024",
    brandName: "DSWD NEWS",
    date: "12/01/2024",
   
  ),
  ProductModel(
    image: "https://kalahi.dswd.gov.ph/media/k2/items/cache/f7a0a54c92471ac4480e727e4ccf93df_XL.jpg?t=20220126_060650",
    title: "4Ps F1KD to address stunting among children-beneficiaries",
    brandName: "DSWD NEWS",
    date: "12/01/2024",
  
  ),
];
List<ProductModel> demoFlashSaleProducts = [
  ProductModel(
    image: productDemoImg5,
    title: "DSWD awards 10 LGUs for Project LAWA at BINHI success stories",
    brandName: "DSWD NEWS",
    date: "12/01/2024",
 
  ),
  ProductModel(
    image: productDemoImg6,
    title: "DSWD’s Walang Gutom Program beneficiaries soar to 259K",
    brandName: "DSWD NEWS",
    date: "12/01/2024",
   
  ),
  ProductModel(
    image: productDemoImg4,
    title: "DSWD’s risk resiliency program helps over 137K beneficiaries in 2024",
    brandName: "DSWD NEWS",
    date: "12/01/2024",
    
  ),
];
List<ProductModel> demoBestSellersProducts = [
  ProductModel(
    image: "https://i.imgur.com/tXyOMMG.png",
    title: "DSWD food packs released to disaster-hit areas breach 1M mark",
    brandName: "DSWD NEWS",
    date: "12/01/2024",
   
  ),
  ProductModel(
    image: "https://i.imgur.com/h2LqppX.png",
    title: "DSWD gives Php4.9M in livelihood aid to 245 typhoon-hit farmers, fisherfolk in Bicol",
    brandName: "Lipsy london",
    date: "12/01/2024",
    
  ),
  ProductModel(
    image: productDemoImg4,
    title: "DSWD to launch ready-to-eat food packs at nat’l convention on climate change mitigation",
    brandName: "Lipsy london",
    date: "12/01/2024",
    
  ),
];
List<ProductModel> kidsProducts = [
  ProductModel(
    image: "https://i.imgur.com/dbbT6PA.png",
    title: "DSWD’s Nat’l Training School for Boys celebrates 55th anniversary",
    brandName: "Lipsy london",
    date: "12/01/2024",
   
  ),
  ProductModel(
    image: "https://i.imgur.com/7fSxC7k.png",
    title: "Printed Sleeveless Tiered Swing Dress",
    brandName: "Lipsy london",
    date: "12/01/2024",
  ),
  ProductModel(
    image: "https://i.imgur.com/pXnYE9Q.png",
    title: "Ruffle-Sleeve Ponte-Knit Sheath ",
    brandName: "Lipsy london",
    date: "12/01/2024",
  ),
  ProductModel(
    image: "https://i.imgur.com/V1MXgfa.png",
    title: "Green Mountain Beta Warehouse",
    brandName: "Lipsy london",
    date: "12/01/2024",
   
  ),
  ProductModel(
    image: "https://i.imgur.com/8gvE5Ss.png",
    title: "Printed Sleeveless Tiered Swing Dress",
    brandName: "Lipsy london",
    date: "12/01/2024",
  ),
  ProductModel(
    image: "https://i.imgur.com/cBvB5YB.png",
    title: "Mountain Beta Warehouse",
    brandName: "Lipsy london",
    date: "12/01/2024",
  ),
];
