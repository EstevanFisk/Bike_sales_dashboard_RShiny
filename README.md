# 🚲 Predictive Retail Analytics: Sales Forecasting & Pricing Suite

[![R](https://img.shields.io/badge/Language-R-276DC3.svg?style=flat&logo=r)](https://www.r-project.org/)
[![Shiny](https://img.shields.io/badge/Framework-Shiny-176BEF.svg?style=flat&logo=rstudio)](https://shiny.posit.co/)
[![XGBoost](https://img.shields.io/badge/Model-XGBoost-black?style=flat)](https://xgboost.ai/)
[![Hosted](https://img.shields.io/badge/Hosted-Shinyapps.io-blue?style=flat)](https://www.shinyapps.io/)

This integrated suite provides a simulated bicycle retail business with two core data science tools: a **Demand Forecasting & Customer Analytics Dashboard** and a **Machine Learning-Driven Price Prediction Tool**. Together, they transform raw sales and product data into actionable strategic insights for inventory management and sales optimization.

---

## 📊 Dashboard 1: Demand Forecasting & Customer Analytics

Designed for executive stakeholders, this dashboard operationalizes advanced time-series analytics into a user-friendly interface for proactive business planning.

### Business Value & Impact
* **Strategic Resource Allocation:** Rapidly evaluate revenue concentration by geographic market to focus sales efforts.
* **Performance Monitoring:** Utilizes "Health & Wealth" metrics (e.g., volume thresholds and revenue markers) to instantly flag underperforming segments.
* **Proactive Planning:** Replaces reactive management with ML-integrated forecasting, allowing teams to hedge against inventory risks and sales target misses.

### Technical Methodology
* **Forecasting Engine:** Utilizes machine learning models (XGBoost) over traditional ARIMA methods to achieve faster performance and greater versatility across daily, weekly, and monthly time divisions.
* **Feature Engineering:** Leveraged the `timetk` package to derive extensive time-series features, significantly boosting real-time prediction accuracy.
* **Visualizations:** Features localized trend detection via **LOESS smoothers** and revenue density mapping through thematic state choropleths.

---

## 🛠️ Dashboard 2: ML-Driven Product Price Prediction

This tool empowers sales teams with self-service pricing capabilities, reducing friction in the sales cycle and ensuring internal margin consistency.



### Business Value & Impact
* **Field-Level Autonomy:** Decouples sales representatives from central pricing teams, enabling real-time quotes during the deal cycle.
* **Margin Consistency:** Prevents "margin leakage" by ensuring new bike configurations are priced accurately relative to the existing product portfolio.
* **Operational Throughput:** Automates routine pricing inquiries, shifting product management focus toward high-level strategic initiatives.

### Technical Overview
* **Model Integration:** Powered by an **XGBoost regression model** trained via the `parsnip` framework.
* **Interactive UI:** Built using `flexdashboard` and `shinyjs`, allowing users to input parameters (Base Model, Tier, Features) and receive a dynamic prediction.
* **Responsive Visualization:** Uses `Plotly` to render a violin-jitter plot, contextualizing the predicted price within the actual distribution of existing bike families.

---

## 🧰 Technical Stack

| Component | Technology | Role |
| :--- | :--- | :--- |
| **Orchestration** | `Shiny` / `flexdashboard` | Reactive web interface and dashboard layout. |
| **Modeling** | `XGBoost` / `parsnip` | Predictive regression for pricing and forecasting. |
| **Time Series** | `timetk` | Feature engineering for seasonal and trend data. |
| **Data Layer** | `RSQLite` | Structured storage for bicycle and sales data. |
| **Visualization** | `Plotly` / `ggplot2` | Interactive, production-grade graphing. |
| **Deployment** | `shinyapps.io` | Cloud-based hosting for global accessibility. |

---

## 🚀 Live Demo
**Try the apps here:** [Demand Forecasting Dashboard](https://estevanfisk.com/projects/bike_rshiny_dashboard/demand_app/) and [ML Product Price Prediction Tool](https://estevanfisk.com/projects/bike_rshiny_dashboard/pricing_app/)

---

## ⚙️ Installation & Local Use

To run these applications locally, ensure you have R installed and follow these steps:

1.  **Clone the repository:**
    ```bash
    git clone [https://github.com/yourusername/predictive-retail-suite.git](https://github.com/yourusername/predictive-retail-suite.git)
    ```
2.  **Install required dependencies:**
    ```R
    install.packages(c("shiny", "flexdashboard", "xgboost", "parsnip", "plotly", "tidyquant", "RSQLite"))
    ```
3.  **Open the app:**
    Open `price_prediction_app.Rmd` in RStudio and click **Run Document**.

---

## 🏛️ Acknowledgments
* **Business Science University:** Original methodologies and coursework context.
* **Cannondale:** Brand inspiration and simulated data architecture.

> **Personal Note:** As a Data Scientist with a focus on operationalizing analytics, this project represents my commitment to building tools that don't just "show" data, but drive direct business decisions through machine learning.