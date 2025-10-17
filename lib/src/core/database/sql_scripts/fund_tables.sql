-- 基金数据表结构定义
-- JiSuDB 数据库表结构

-- 基金基础信息表
CREATE TABLE Fund_Basic_Info (
    fund_code NVARCHAR(20) PRIMARY KEY,
    fund_name NVARCHAR(200) NOT NULL,
    fund_type NVARCHAR(50) NOT NULL,
    company NVARCHAR(100) NOT NULL,
    manager NVARCHAR(100),
    risk_level NVARCHAR(10),
    status NVARCHAR(20) DEFAULT 'active',
    scale DECIMAL(18,2), -- 基金规模（亿元）
    unit_nav DECIMAL(18,4), -- 单位净值
    accumulated_nav DECIMAL(18,4), -- 累计净值
    daily_return DECIMAL(8,4), -- 日涨跌幅
    establish_date DATE, -- 成立日期
    management_fee DECIMAL(5,4), -- 管理费率
    custody_fee DECIMAL(5,4), -- 托管费率
    purchase_fee DECIMAL(5,4), -- 申购费率
    redemption_fee DECIMAL(5,4), -- 赎回费率
    minimum_investment DECIMAL(18,2), -- 最低投资额
    performance_benchmark NVARCHAR(500), -- 业绩比较基准
    investment_target NVARCHAR(1000), -- 投资目标
    investment_scope NVARCHAR(1000), -- 投资范围
    currency NVARCHAR(10) DEFAULT 'CNY', -- 货币类型
    listing_date DATE, -- 上市日期
    delisting_date DATE, -- 退市日期
    created_at DATETIME2 DEFAULT GETDATE(),
    updated_at DATETIME2 DEFAULT GETDATE()
);

-- 基金业绩数据表
CREATE TABLE Fund_Performance (
    id INT IDENTITY(1,1) PRIMARY KEY,
    fund_code NVARCHAR(20) NOT NULL,
    return_1w DECIMAL(8,4), -- 近1周收益率
    return_1m DECIMAL(8,4), -- 近1月收益率
    return_3m DECIMAL(8,4), -- 近3月收益率
    return_6m DECIMAL(8,4), -- 近6月收益率
    return_1y DECIMAL(8,4), -- 近1年收益率
    return_3y DECIMAL(8,4), -- 近3年收益率
    return_ytd DECIMAL(8,4), -- 今年以来收益率
    return_since_inception DECIMAL(8,4), -- 成立以来收益率
    sharpe_ratio DECIMAL(8,4), -- 夏普比率
    max_drawdown DECIMAL(8,4), -- 最大回撤
    volatility DECIMAL(8,4), -- 波动率
    performance_date DATE NOT NULL,
    created_at DATETIME2 DEFAULT GETDATE(),
    FOREIGN KEY (fund_code) REFERENCES Fund_Basic_Info(fund_code)
);

-- 基金净值历史表
CREATE TABLE Fund_NAV_History (
    id INT IDENTITY(1,1) PRIMARY KEY,
    fund_code NVARCHAR(20) NOT NULL,
    nav_date DATE NOT NULL,
    unit_nav DECIMAL(18,4) NOT NULL, -- 单位净值
    accumulated_nav DECIMAL(18,4) NOT NULL, -- 累计净值
    daily_return DECIMAL(8,4), -- 日涨跌幅
    created_at DATETIME2 DEFAULT GETDATE(),
    FOREIGN KEY (fund_code) REFERENCES Fund_Basic_Info(fund_code),
    UNIQUE(fund_code, nav_date)
);

-- 基金公司信息表
CREATE TABLE Fund_Company (
    company_code NVARCHAR(50) PRIMARY KEY,
    company_name NVARCHAR(200) NOT NULL,
    company_short_name NVARCHAR(100),
    establishment_date DATE,
    registered_capital DECIMAL(18,2),
    company_type NVARCHAR(50),
    legal_representative NVARCHAR(100),
    headquarters_location NVARCHAR(200),
    website_url NVARCHAR(500),
    contact_phone NVARCHAR(50),
    total_funds_under_management INT DEFAULT 0,
    total_asset_under_management DECIMAL(18,2),
    company_rating NVARCHAR(10),
    rating_agency NVARCHAR(100),
    created_at DATETIME2 DEFAULT GETDATE(),
    updated_at DATETIME2 DEFAULT GETDATE()
);

-- 基金经理信息表
CREATE TABLE Fund_Manager (
    manager_code NVARCHAR(50) PRIMARY KEY,
    manager_name NVARCHAR(100) NOT NULL,
    avatar_url NVARCHAR(500),
    education_background NVARCHAR(500),
    professional_experience NVARCHAR(2000),
    manage_start_date DATE,
    total_manage_duration INT, -- 管理总天数
    current_fund_count INT DEFAULT 0,
    total_asset_under_management DECIMAL(18,2),
    average_return_rate DECIMAL(8,4),
    best_fund_performance DECIMAL(8,4),
    risk_adjusted_return DECIMAL(8,4),
    created_at DATETIME2 DEFAULT GETDATE(),
    updated_at DATETIME2 DEFAULT GETDATE()
);

-- 基金持仓信息表
CREATE TABLE Fund_Holding (
    id INT IDENTITY(1,1) PRIMARY KEY,
    fund_code NVARCHAR(20) NOT NULL,
    stock_code NVARCHAR(20) NOT NULL,
    stock_name NVARCHAR(100) NOT NULL,
    holding_quantity DECIMAL(18,2),
    holding_value DECIMAL(18,2),
    holding_percentage DECIMAL(8,4), -- 占基金资产比例
    market_value DECIMAL(18,2), -- 持仓市值
    holding_date DATE NOT NULL,
    is_top_ten BIT DEFAULT 0, -- 是否为十大重仓股
    created_at DATETIME2 DEFAULT GETDATE(),
    FOREIGN KEY (fund_code) REFERENCES Fund_Basic_Info(fund_code)
);

-- 基金排行数据表
CREATE TABLE Fund_Ranking (
    id INT IDENTITY(1,1) PRIMARY KEY,
    fund_code NVARCHAR(20) NOT NULL,
    fund_name NVARCHAR(200) NOT NULL,
    fund_type NVARCHAR(50) NOT NULL,
    company NVARCHAR(100) NOT NULL,
    ranking_position INT NOT NULL,
    total_count INT NOT NULL,
    return_1w DECIMAL(8,4),
    return_1m DECIMAL(8,4),
    return_3m DECIMAL(8,4),
    return_1y DECIMAL(8,4),
    return_ytd DECIMAL(8,4),
    return_since_inception DECIMAL(8,4),
    sharpe_ratio DECIMAL(8,4),
    max_drawdown DECIMAL(8,4),
    volatility DECIMAL(8,4),
    time_period NVARCHAR(50) NOT NULL,
    ranking_date DATE NOT NULL,
    created_at DATETIME2 DEFAULT GETDATE(),
    FOREIGN KEY (fund_code) REFERENCES Fund_Basic_Info(fund_code)
);

-- 用户收藏基金表
CREATE TABLE User_Favorite_Fund (
    id INT IDENTITY(1,1) PRIMARY KEY,
    user_id NVARCHAR(100) NOT NULL,
    fund_code NVARCHAR(20) NOT NULL,
    added_date DATETIME2 DEFAULT GETDATE(),
    notes NVARCHAR(1000),
    is_active BIT DEFAULT 1,
    FOREIGN KEY (fund_code) REFERENCES Fund_Basic_Info(fund_code),
    UNIQUE(user_id, fund_code)
);

-- 创建索引优化查询性能
CREATE INDEX IX_Fund_Performance_fund_code ON Fund_Performance(fund_code);
CREATE INDEX IX_Fund_Performance_performance_date ON Fund_Performance(performance_date);
CREATE INDEX IX_Fund_NAV_History_fund_code ON Fund_NAV_History(fund_code);
CREATE INDEX IX_Fund_NAV_History_nav_date ON Fund_NAV_History(nav_date);
CREATE INDEX IX_Fund_Holding_fund_code ON Fund_Holding(fund_code);
CREATE INDEX IX_Fund_Holding_holding_date ON Fund_Holding(holding_date);
CREATE INDEX IX_Fund_Ranking_ranking_date ON Fund_Ranking(ranking_date);
CREATE INDEX IX_Fund_Ranking_fund_type ON Fund_Ranking(fund_type);

-- 创建视图：基金最新业绩视图
GO
CREATE VIEW vw_Fund_Latest_Performance AS
SELECT
    f.fund_code,
    f.fund_name,
    f.fund_type,
    f.company,
    f.manager,
    f.risk_level,
    f.scale,
    p.return_1w,
    p.return_1m,
    p.return_3m,
    p.return_6m,
    p.return_1y,
    p.return_3y,
    p.return_ytd,
    p.return_since_inception,
    p.sharpe_ratio,
    p.max_drawdown,
    p.volatility,
    p.performance_date,
    ROW_NUMBER() OVER (PARTITION BY f.fund_code ORDER BY p.performance_date DESC) as rn
FROM Fund_Basic_Info f
LEFT JOIN Fund_Performance p ON f.fund_code = p.fund_code
WHERE f.status = 'active';
GO

-- 创建存储过程：获取基金排行数据
CREATE PROCEDURE sp_GetFundRanking
    @fund_type NVARCHAR(50) = NULL,
    @time_period NVARCHAR(50) = '近1年',
    @top_n INT = 100
AS
BEGIN
    SELECT TOP (@top_n)
        r.fund_code,
        r.fund_name,
        r.fund_type,
        r.company,
        r.ranking_position,
        r.total_count,
        r.return_1y,
        r.sharpe_ratio,
        r.max_drawdown,
        r.volatility,
        r.ranking_date
    FROM Fund_Ranking r
    WHERE (@fund_type IS NULL OR r.fund_type = @fund_type)
        AND r.time_period = @time_period
    ORDER BY r.ranking_position;
END;
GO