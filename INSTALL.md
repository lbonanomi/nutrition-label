Add a `.github/workflows/main.yml` file to whatever Github repository you want this action to run-in.

The below workflow re-runs the labeler every 4 hours

```
name: Labeler

on:
  schedule:
    - cron: "0 */4 * * *"

jobs:
  generate_content_label:
    runs-on: ubuntu-latest

    env:
      TOKEN: ${{ secrets.TOKEN }}   

    steps:
    - name: User Nutrition Label
      uses: lbonanomi/nutrition-label@1.1
      with:
        count-forked: 'false'
```
