export interface SystemAlarms {
  [key: string]: Alarm[];
}

export interface Alarm {
  name: string;
  last_raised: number;
  status: string;
  value: string;
}
