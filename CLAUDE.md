- 在每次开发时不定制查看doc\下的文件或README文件
- 为项目的代码添加文档注释
- 使用中文回答
- 使用的bash命令是windows的
- 使用API调用的方式， http://154.44.25.92:8080/ 这是自己搭建的，https://aktools.akfamily.xyz/aktools/官方使用文档
- 遵循 AKshare官方文档进行操作https://akshare.akfamily.xyz/data/fund/fund_public.html#基金的详细操作
- 在每次完成某个进度更新PROGRESS.md文件
- 在完成项目版某个版本后是否进行修改、错误修复等操作 进行小版本的更新 如0.5.1
- 在项目的指定文件夹中创建相关的文件
- 在项目架构的开发中你是一个严谨的架构师
- 在项目的UI开发中你是一个想象力无穷大的UI设计师\开发者
- 在项目开发中你是一个精通各种语言的高级程序眼
- 在项目测试中你是一个一丝不苟的测试员，只有保证测试输出正确才能应用该方法


以下是针对基金 API的**数据快速缓存 3 步操作清单**，结合 Flutter 工具链和性能优化要点，可直接落地：

### **第 1 步：高效请求 —— 减少数据传输耗时**

**核心目标**：用最少的请求和数据量获取所需内容，降低网络耗时。

* **工具**：Dio（Flutter 主流 HTTP 库）
* **操作要点**：
  1. 启用压缩：配置 `Dio` 支持 `gzip` 压缩（请求头加 `Accept-Encoding: gzip`），API 返回数据体积可减少 50%-70%。
     dart

     ```dart
     final dio = Dio()..options.headers = {'Accept-Encoding': 'gzip'};
     ```
  2. 批量拉取：若 API 支持分页 / 批量参数（如 `?page=1&size=1000`），一次请求拉取尽可能多的数据（如 1000 条 / 次），减少请求次数（避免多次建立连接的开销）。
  3. 复用连接：开启 `HTTP/2`（需 API 服务器支持），通过连接复用减少 TCP 握手耗时，Dio 默认支持 HTTP/2。

### **第 2 步：快速解析 —— 异步处理 + 精简数据**

**核心目标**：避免解析耗时阻塞 UI，只保留缓存必要字段。

* **工具**：`compute`（Flutter 异步计算）+ `json_serializable`（高效 JSON 解析）
* **操作要点**：
  1. 异步解析：用 `compute` 在独立 isolate 中解析 JSON，不阻塞主线程（尤其数据量 > 1 万条时）。
     dart

     ```dart
     // 子线程解析
     List<FundInfo> parseFunds(String responseBody) {
       final jsonData = json.decode(responseBody)['data'];
       return (jsonData as List).map((i) => FundInfo.fromJson(i)).toList();
     }
     // 调用：
     final response = await dio.get(apiUrl);
     final funds = await compute(parseFunds, response.data); // 异步解析
     ```
  2. 精简字段：模型类 `FundInfo` 只保留缓存必要字段（如 `code`/`name`/`company`），丢弃冗余字段（如临时统计数据），减少解析和存储耗时。

### **第 3 步：高效存储 —— 批量写入 + 同步建索引**

**核心目标**：用最快速度写入缓存，并同步构建查询索引（为后续搜索提速）。

* **工具**：Hive（轻量 NoSQL 数据库，比 SharedPreferences 快 10 倍 +）
* **操作要点**：
  1. 批量写入：用 Hive 的 `putAll` 批量存储数据（比循环 `put` 快 3-5 倍）。
     dart

     ```dart
     // 初始化Hive盒子
     final fundBox = await Hive.openBox<FundInfo>('funds');
     // 批量写入（key用基金代码，方便后续精确查询）
     await fundBox.putAll({for (var f in funds) f.code: f});
     ```
  2. 同步建索引：写入缓存时，同步构建内存索引（如哈希表 / 前缀树），避免后续搜索时再遍历缓存。
     dart

     ```dart
     // 构建基金名称前缀树（同步写入时执行）
     final nameTrie = TrieTree();
     for (var f in funds) {
       nameTrie.insert(f.name, f.code); // 插入名称和对应基金代码
     }
     // 索引存入内存缓存（如全局单例）
     FundCacheManager.instance.nameTrie = nameTrie;
     ```

### **额外提速技巧**

* 预请求时机：在 APP 启动后、用户首次进入搜索页前，用空闲时间（如 `WidgetsBinding.instance.addPostFrameCallback`）触发请求 + 缓存流程，用户操作时数据已就绪。
* 缓存失效策略：给缓存加时间戳（如 6 小时过期），过期后仅增量更新变化数据（通过 API 返回的 `updateTime` 字段判断），避免全量重拉。

按这 3 步操作，可将 “API 请求→缓存完成” 的总耗时压缩至 1 秒内（针对 1 万条基金数据），且后续搜索可直接基于内存索引实现毫秒级响应。
