import 'reflect-metadata';
import { NestFactory } from '@nestjs/core';
import { AppModule } from './app.module';

async function bootstrap(): Promise<void> {
  const app = await NestFactory.create(AppModule);
  app.setGlobalPrefix('v1', { exclude: ['health'] });
  const port = Number(process.env.PORT ?? 3000);
  await app.listen(port);
  console.log(`OLA STATION API démarrée sur le port ${port}`);
}

void bootstrap();
