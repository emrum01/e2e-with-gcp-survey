import { test, expect } from '@playwright/test';

test.describe('Home Page', () => {
  test('should display the home page', async ({ page }) => {
    await page.goto('/');
    
    // タイトルの確認
    await expect(page).toHaveTitle(/Next.js/);
    
    // メインコンテンツの確認
    const main = page.getByRole('main');
    await expect(main).toBeVisible();
  });
});
