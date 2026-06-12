class CategoryModel {
  final String title;
  final String? image, svgSrc;
  final List<CategoryModel>? subCategories;

  CategoryModel({
    required this.title,
    this.image,
    this.svgSrc,
    this.subCategories,
  });
}

//  CategoryModel(name: "NGAs", svgSrc: "assets/icons/NGAs.svg"),
//   CategoryModel(name: "LGUs", svgSrc: "assets/icons/LGUs.svg"),
//   CategoryModel(name: "Jobs", svgSrc: "assets/icons/Jobs.svg"),
//   CategoryModel(name: "Tourism", svgSrc: "assets/icons/Tourism.svg"),
//   CategoryModel(name: "Travel", svgSrc: "assets/icons/Travel.svg"),
//   CategoryModel(name: "Start-Up", svgSrc: "assets/icons/StartUp.svg"),
//   CategoryModel(name: "Health", svgSrc: "assets/icons/Health.svg"),
//   CategoryModel(name: "More", svgSrc: "assets/icons/More.svg"),


final List<CategoryModel> demoCategoriesWithImage = [
  CategoryModel(title: "Attendance", image: "https://i.imgur.com/5M89G2P.png"),
  CategoryModel(title: "Documents", image: "https://i.imgur.com/UM3GdWg.png"),
  CategoryModel(title: "Directory", image: "https://i.imgur.com/Lp0D6k5.png"),
  CategoryModel(title: "Request", image: "https://i.imgur.com/3mSE5sN.png"),
  CategoryModel(title: "Leaves", image: "https://i.imgur.com/3mSE5sN.png"),
];

final List<CategoryModel> demoCategories = [
  CategoryModel(
    title: "On sale",
    svgSrc: "assets/icons/Sale.svg",
    subCategories: [
      CategoryModel(title: "All Clothing"),
      CategoryModel(title: "New In"),
      CategoryModel(title: "Coats & Jackets"),
      CategoryModel(title: "Dresses"),
      CategoryModel(title: "Jeans"),
    ],
  ),
  CategoryModel(
    title: "Man’s & Woman’s",
    svgSrc: "assets/icons/Man&Woman.svg",
    subCategories: [
      CategoryModel(title: "All Clothing"),
      CategoryModel(title: "New In"),
      CategoryModel(title: "Coats & Jackets"),
    ],
  ),
  CategoryModel(
    title: "Kids",
    svgSrc: "assets/icons/Child.svg",
    subCategories: [
      CategoryModel(title: "All Clothing"),
      CategoryModel(title: "New In"),
      CategoryModel(title: "Coats & Jackets"),
    ],
  ),
  CategoryModel(
    title: "Accessories",
    svgSrc: "assets/icons/Accessories.svg",
    subCategories: [
      CategoryModel(title: "All Clothing"),
      CategoryModel(title: "New In"),
    ],
  ),
];
