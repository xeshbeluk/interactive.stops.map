
# 📍 Bus Stop Demographic & Ridership Map

This interactive map highlights **hotspots** (dense, low-ridership stops) and overlays demographic characteristics using color-coded layers from the **2022 American Community Survey**.

---

## 🗺️ Map Guidelines

- The **legend** (top-right corner) explains the color scheme. For example, with a red-to-green gradient:
  - **Red** = lower median income
  - **Green** = higher median income

### 🎛️ Left Panel Controls

- **Select a Demographic Variable:** Choose from options like:
  - Age, Race/Ethnicity, Sex
  - Household Size, Education Level
  - Native English Speakers
  - Median Income
  - Safety Perception
  - Customer Satisfaction

- **Filter by Subgroup** (if applicable): E.g., select only one age group or race.

- **Search Functionality:**
  - **By Stop Name**: Highlights matching stops (**green dots**) and routes.
  - **By Route Number**: Displays the selected **route** (**blue**) and associated stops.

### 🧭 Map Controls

- **Hotspot Toggle**: 
  - Show/hide **hotspots** (**red**) and **other stops** (**grey**).
- **Opacity Slider**: Adjust demographic layer transparency.
- **Color Scheme Menu**: Choose from standard and TriMet-themed palettes.
- **Zoom & Download**: Available in the top-left corner.
- **Interactive Elements**: Click on any map element for more detail.

---

## 🆘 Additional Help

### 🔥 Filter Hotspots by Urgency

Use the **urgency slider** to adjust cutoff criteria:
- Higher urgency = Stops with **lowest ridership** and **highest population density**.

---

### 🧮 Buffer Selection Tool (Top-Left Corner)

Use this tool to filter stops spatially:

1. **Manual Polygon**: Click to draw custom shape; click the starting point to close.
2. **Rectangle**: Click + drag to form a rectangle.
3. **Circle**: Click at the center, drag to set radius.

> 🧹 Use the **"Clear search bar and remove buffers"** button to reset selections.

---

## 📊 Expanded Table

The **Expanded Table tab** provides detailed demographic and ridership data for each bus stop (within a 1/4 mile radius).  

### Column Descriptions

| Column Name | Description |
|-------------|-------------|
| `LOCATION_ID` | Stop location ID |
| `stop_name` | Stop name |
| `estimated_pop_density` | Estimated population density |
| `average_total_ons` | Average total boardings |
| `average_total_offs` | Average total alightings |
| `white_nh` | White, non-Hispanic |
| `black` | Black |
| `native` | American Indian / Alaska Native |
| `asian` | Asian |
| `pacific` | Native Hawaiian / Pacific Islander |
| `hispanic` | Latino or Hispanic |
| `other_race` | Other races |
| `two_races` | Two or more races |
| `male` | Male |
| `female` | Female |
| `age_below_18` | Under 18 |
| `age_18_29` | Age 18–29 |
| `age_30_44` | Age 30–44 |
| `age_45_54` | Age 45–54 |
| `age_55_64` | Age 55–64 |
| `age_65_more` | Over 65 |
| `educ_no_school` | No high school education |
| `educ_high_or_less` | High school graduate, no college degree |
| `educ_bach_or_less` | Bachelor's degree |
| `educ_master` | Master's degree |
| `educ_prof` | Professional degree |
| `educ_phd` | PhD |
| `english_native` | Native English speakers |
| `average_household_size` | Average household size |
| `median_income` | Median annual income |
